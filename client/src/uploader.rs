use crate::connection::{ChannelMessage, JoinReference, MessageType, MsgReference, Topic};
use serde_json::Value;
use std::path::PathBuf;
use tokio::sync::mpsc::UnboundedSender;
use uuid::Uuid;

pub trait Uploader {
    /// Join Channel allows us to join the Phoenix channel for our upload - we can't incorporate this
    /// into `init` due to a potential race condition in which the reply for join message would be handled
    /// before the `Upload` struct is available to handle it.
    async fn request_join_channel(&self) -> Result<(), UploaderError>;

    /// Public facing handle function for taking incoming messages assigned to this uploader. This allows
    /// us to obfuscate the rest of the message handling and isolate it to the uploader - allowing
    /// for quick changes internally, as well as potentially moving to a different uploader if need be
    async fn handle_msg(&self, channel_message: ChannelMessage) -> Result<(), UploaderError>;
}

/// Uploader contains all the logic for handling the multipart uploads - it accepts channels and such
/// out to the main thread which has the websocket on it. While this is in scope we assume that an
/// upload is happening, or that an action needs to be performed.
///
/// The uploader uses the same websocket connection as the primary connection thread but will be joining
/// and sending messages on it its own topic in order to keep a separation of concerns between uploading
/// processes and main thread (also lets us get away with multiple message indices)
pub struct LakeFsUploader {
    pub id: Uuid,
    pub file_path: PathBuf,
    db: rocksdb::DB,
    tx: UnboundedSender<ChannelMessage>,
}

impl LakeFsUploader {
    /// New opens the DB and prepares everything for upload.
    pub async fn new(
        id: Uuid,
        file_path: PathBuf,
        tx: UnboundedSender<ChannelMessage>,
    ) -> Result<LakeFsUploader, UploaderError> {
        // open the db - path, one db per uploader - will delete after we're done
        // even though we're opening in SingleThread mode - reading the docs shows that most ops
        // are multithreaded - it's mainly for when you have multiple configuration groups which we
        // currently do not
        let db = rocksdb::DB::open_default(format!(".ingest_databases/{id}"))?;
        tokio::fs::try_exists(&file_path).await?;

        Ok(LakeFsUploader {
            id,
            file_path,
            db,
            tx,
        })
    }
}

impl Uploader for LakeFsUploader {
    async fn request_join_channel(&self) -> Result<(), UploaderError> {
        let channel_message = ChannelMessage(
            JoinReference(Some(0)),
            MsgReference(0.to_string()),
            Topic(format!("uploader:{}", self.id)),
            MessageType::Join,
            Value::Null,
        );

        self.tx.send(channel_message)?;
        Ok(())
    }

    async fn handle_msg(&self, channel_message: ChannelMessage) -> Result<(), UploaderError> {
        Ok(())
    }
}

use thiserror::Error;

#[derive(Error, Debug)]
pub enum UploaderError {
    #[error("rocksdb error: {0}")]
    RocksDB(#[from] rocksdb::Error),
    #[error("io error: {0}")]
    IO(#[from] std::io::Error),
    #[error("internal error: {0}")]
    Internal(String),
    #[error("websocket channel send error: {0}")]
    Websocket(#[from] tokio::sync::mpsc::error::SendError<ChannelMessage>),
    #[error("not implemented")]
    NotImplemented,
}
