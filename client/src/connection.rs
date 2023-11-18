use crate::config::get_configuration;
use crate::errors::ClientError;
use crate::Connected;
use futures_util::{StreamExt, TryStreamExt};
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_tungstenite::tungstenite::{Error, Message};
use tracing::error;

pub async fn make_connection_thread(semaphore: Arc<RwLock<Connected>>) -> Result<(), ClientError> {
    let thread_semaphore = semaphore.clone();
    let handle = tokio::spawn(async move { make_connection(thread_semaphore).await });

    // switch the connected status prior to fully exiting
    let result = handle.await?;

    // the write-lock will be dropped once the function goes out of scope
    let mut connected = semaphore.write().await;
    *connected = Connected(false);

    result
}

async fn make_connection(semaphore: Arc<RwLock<Connected>>) -> Result<(), ClientError> {
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

    // indicate status, has to be in own scope so we drop the write lock immediately
    {
        let mut connected = semaphore.write().await;
        *connected = Connected(true);
    }

    let (write, mut read) = ws.split();

    loop {
        match read.try_next().await {
            Ok(msg) => {
                let msg = match msg {
                    None => continue,
                    Some(msg) => msg,
                };

                match msg {
                    Message::Text(_) => {}
                    Message::Binary(_) => {}
                    Message::Ping(_) => {}
                    Message::Pong(_) => {}
                    Message::Close(_) => break,
                    Message::Frame(_) => {}
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
