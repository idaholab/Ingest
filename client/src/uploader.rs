use crate::connection::{ChannelMessage, JoinReference, MessageType, MsgReference, Topic};
use rocksdb::IteratorMode;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::path::PathBuf;
use thiserror::Error;
use tokio::sync::mpsc::UnboundedSender;
use uuid::Uuid;

/// Uploader contains all the logic for handling the multipart uploads - it accepts channels and such
/// out to the main thread which has the websocket on it. While this is in scope we assume that an
/// upload is happening, or that an action needs to be performed.
///
/// The uploader uses the same websocket connection as the primary connection thread but will be joining
/// and sending messages on it its own topic in order to keep a separation of concerns between uploading
/// processes and main thread (also lets us get away with multiple message indices)
pub struct Uploader {
    pub id: Uuid,
    pub file_path: PathBuf,
    pub num_parts: usize,
    db: rocksdb::DB,
    tx: UnboundedSender<ChannelMessage>,
}

impl Uploader {
    /// New opens the DB and prepares everything for upload.
    pub async fn new(
        id: Uuid,
        file_path: PathBuf,
        tx: UnboundedSender<ChannelMessage>,
    ) -> Result<Uploader, UploaderError> {
        // open the db - path, one db per uploader - will delete after we're done
        // even though we're opening in SingleThread mode - reading the docs shows that most ops
        // are multithreaded - it's mainly for when you have multiple configuration groups which we
        // currently do not
        let db = rocksdb::DB::open_default(format!(".ingest_databases/{id}"))?;
        // verify the file exists, then grab its data to make some assumptions about how many parts
        // to split it into
        tokio::fs::try_exists(&file_path).await?;
        let stats = tokio::fs::metadata(&file_path).await?;
        let max_parts = 10_000;
        let mut chunk_size = (1024 * 1024) * 5; // default to 5mb chunk size for now
        let mut num_parts = (stats.len() as f64 / chunk_size as f64).ceil() as usize;

        // we can do a max of 10,000 parts - so if we're above that, we need to up chunk size
        while num_parts > max_parts {
            chunk_size += 1 * 1024 * 1024; // increase chunk size by 1 MB
            num_parts = (stats.len() as f64 / chunk_size as f64).ceil() as usize;
        }

        Ok(Uploader {
            id,
            file_path,
            num_parts,
            db,
            tx,
        })
    }

    pub async fn request_join_channel(&self) -> Result<(), UploaderError> {
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

    pub async fn handle_msg(&self, channel_message: ChannelMessage) -> Result<(), UploaderError> {
        Ok(())
    }

    pub async fn request_status(&self) -> Result<(), UploaderError> {
        // we want to make sure this doesn't get in the way of actual uploading so we're going to take
        // a snapshot of the db instead of iterating over the live thing
        let snapshot = self.db.snapshot();
        // if they're in the db, they're uploaded
        let parts_uploaded = snapshot.iterator(IteratorMode::Start).count();

        let channel_message = ChannelMessage(
            JoinReference(Some(0)),
            MsgReference(0.to_string()),
            Topic(format!("uploader:{}", self.id)),
            MessageType::Status,
            serde_json::value::to_value(StatusMessagePayload {
                parts_sent: parts_uploaded,
                parts_remaining: self.num_parts - parts_uploaded,
            })?,
        );

        self.tx.send(channel_message)?;
        Ok(())
    }
}

#[derive(Serialize, Deserialize)]
struct StatusMessagePayload {
    parts_sent: usize,
    parts_remaining: usize,
}

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
    #[error("json error {0}")]
    JSON(#[from] serde_json::Error),
}
