use crate::config::get_configuration;
use crate::errors::ClientError;
use crate::Connected;
use futures_util::{SinkExt, StreamExt, TryStreamExt};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::time::sleep;
use tokio_tungstenite::tungstenite::{Error, Message};
use tracing::{error, info};

#[derive(Clone, Serialize, Deserialize)]
enum DestinationType {
    #[serde(rename = "azure")]
    Azure,
    #[serde(rename = "s3")]
    S3,
    #[serde(rename = "lakefs")]
    LakeFS,
}

#[derive(Clone, Deserialize, Serialize, Debug)]
enum MessageType {
    #[serde(rename = "part_request")]
    PartRequest,
    #[serde(rename = "status")]
    Status,
    #[serde(rename = "complete_upload")]
    Complete,
    #[serde(rename = "initiate_upload")]
    InitiateUpload,
    #[serde(rename = "phx_reply")]
    Reply,
    #[serde(rename = "heartbeat")]
    Heartbeat,
    #[serde(rename = "phx_join")]
    Join,
}

#[derive(Clone, Deserialize, Serialize)]
pub struct InitiateUploadPayload {
    id: String,
    destination_type: DestinationType,
    file_path: String,
}

#[derive(Deserialize, Serialize, Debug)]
struct JoinReference(Option<usize>);
#[derive(Deserialize, Serialize, Debug)]
struct MsgReference(usize);
#[derive(Deserialize, Serialize, Debug)]
struct Topic(String);
// we cast the payload as a value from serde_json so we can deserialize into a struct based on the
// inbound message type - there has to be an easier way to do this?
#[derive(Deserialize, Serialize, Debug)]
pub struct ChannelMessage(JoinReference, MsgReference, Topic, MessageType, Value);

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
    let (mut tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<ChannelMessage>();

    // message passing thread - basically allows us to fan out the writers and then bring them back
    // and send out on the same websocket writer
    tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            // convert to json and send
            let msg = match serde_json::to_string(&msg) {
                Ok(m) => m,
                Err(e) => {
                    error!("error in serializing message for channel {:?}", e);
                    continue;
                }
            };

            match write.send(Message::Text(msg)).await {
                Ok(_) => {}
                Err(e) => {
                    error!("error in sending message to channel {:?}", e);
                }
            }
        }
    });

    // we have to join the channel in order to begin sending/receiving, and we want to do it before
    // we start receiving any messages on the channel
    let client_id = config.hardware_id.unwrap().to_string(); // we want to immediately fail if we don't have one

    tx.send(ChannelMessage(
        JoinReference(Some(0)),
        MsgReference(0),
        Topic(format!("client:{client_id}")),
        MessageType::Join,
        json!("{}"),
    ))?;

    // this is the heartbeat loop. it has its own internal index so we don't have to keep track of
    // and manage a global counter/reference maker
    let heartbeat_tx = tx.clone();
    tokio::spawn(async move {
        let mut index = 1;

        loop {
            sleep(Duration::from_millis(500)).await;

            // heartbeat is a special phoenix message that insures our connection against phoenix
            // automatically dropping it when its timeout is reached - configured in your endpoint.ex file
            let heartbeat = ChannelMessage(
                JoinReference(None),
                MsgReference(index),
                Topic("phoenix".into()),
                MessageType::Heartbeat,
                json!("{}"),
            );

            match heartbeat_tx.send(heartbeat) {
                Ok(_) => {}
                Err(e) => {
                    error!("error sending heartbeat {:?}", e);
                }
            }

            index = index + 1;
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
                        let msg: Result<ChannelMessage, serde_json::Error> =
                            serde_json::from_str(m.as_str());

                        match msg {
                            Ok(m) => {
                                info!("{:?}", m)
                            }
                            Err(e) => {
                                error!("unable to deserialize message into type {:?}", e);
                                continue;
                            }
                        }
                    }
                    Message::Close(_) => {
                        break;
                    }
                    // you'll notice that Ping/Pong aren't considered supported - that's because
                    // Phoenix doesn't have the Ping/Pong protocol implemented - instead they follow
                    // the heartbeat method handled above
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
