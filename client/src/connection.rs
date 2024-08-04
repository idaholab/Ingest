use crate::config::get_configuration;
use crate::errors::ClientError;
use crate::Connected;
use futures_util::{SinkExt, StreamExt, TryStreamExt};
use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::sync::RwLock;
use tokio::time::sleep;
use tokio_tungstenite::tungstenite::{Error, Message};
use tracing::{error, info};

#[derive(Clone)]
enum StackMessage {
    String(String),
    Ping,
    Pong,
    Close,
}

pub async fn make_connection_thread(semaphore: Arc<Mutex<Connected>>) -> Result<(), ClientError> {
    let thread_semaphore = semaphore.clone();
    let handle = tokio::spawn(async move { make_connection(thread_semaphore).await });

    // switch the connected status prior to fully exiting
    let result = handle.await?;

    // the write-lock will be dropped once the function goes out of scope
    let mut connected = semaphore.lock().unwrap();
    *connected = Connected(false);

    result
}

async fn make_connection(semaphore: Arc<Mutex<Connected>>) -> Result<(), ClientError> {
    // we pull the config in yet again because we may have restarted this thread after the token
    // was written to the config in a different thread
    let config = get_configuration()?;

    // make the socket connection
    let url = config.ingest_server.unwrap_or("localhost:4000".to_string());
    let token = config.token.ok_or(ClientError::Token)?;

    let (ws, _) = tokio_tungstenite::connect_async(format!(
        "ws://{}/client/websocket?vsn=2.0.0&token={}",
        url, token
    ))
    .await?;

    // indicate status, has to be in own scope, so we drop the write lock immediately
    {
        let mut connected = semaphore.lock().unwrap();
        *connected = Connected(true);
    }

    let (mut write, mut read) = ws.split();

    let message_stack: VecDeque<StackMessage> = VecDeque::new();
    let message_stack = Arc::new(RwLock::new(message_stack));
    let inner_message_stack = message_stack.clone();

    // we have to join the channel in order to begin sending/receiving, and we want to do it before
    // we start receiving any messages on the channel
    let blank = "{}";
    let client_id = config.hardware_id.unwrap().to_string(); // we want to immediately fail if we don't have one
    write
        .send(Message::Text(
            format!(r###"[0, 0, "client:{client_id}", "phx_join", {blank}]"###),
        ))
        .await?;

    tokio::spawn(async move {
        loop {
            sleep(Duration::from_millis(500)).await;

            // heartbeat is a special phoenix message that insures our connection against phoenix
            // automatically dropping it when its timeout is reached - configured in your endpoint.ex file
            match write
                .send(Message::Text(
                    r###"[0, 1, "phoenix", "heartbeat", {}]"###.into(),
                ))
                .await
            {
                Ok(_) => {}
                Err(e) => {
                    error!("unexpected error in writing to websocket {:?}", e);
                    continue;
                }
            }

            // now we run through the message stack, sending them in order
            while let Some(message) = inner_message_stack.write().await.pop_front() {
                let result = match message.clone() {
                    StackMessage::String(msg) => write.send(Message::Text(msg)).await,
                    StackMessage::Ping => write.send(Message::Ping(Vec::new())).await,
                    StackMessage::Pong => write.send(Message::Pong(Vec::new())).await,
                    StackMessage::Close => write.close().await,
                };

                match result {
                    Ok(_) => {}
                    // log the error and break the loop, so we don't keep sending messages, oh and append the message
                    Err(e) => {
                        inner_message_stack.write().await.push_front(message);
                        error!("error while attempting to send websocket message from stack {:?}", e);
                        break;
                    }
                }
            }
        }
    });

    loop {
        match read.try_next().await {
            Ok(msg) => {
                let msg = match msg {
                    None => continue,
                    Some(msg) => msg,
                };

                match msg {
                    Message::Text(m) => {
                        info!(m)
                    }
                    Message::Ping(_) => message_stack.write().await.push_back(StackMessage::Ping),
                    Message::Pong(_) => message_stack.write().await.push_back(StackMessage::Pong),
                    Message::Close(_) => {
                        message_stack.write().await.push_back(StackMessage::Pong);
                        break;
                    }
                    _ => error!("unsupported websocket message type"),
                }
            }
            Err(e) => {
                error!("unexpected drop of websocket connection {:?}", e);
                break;
            }
        }
    }

    Ok(())
}
