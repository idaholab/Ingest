use crate::connection;
use crate::uploader::UploaderError;
use std::io;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ClientError {
    #[error("unable to load configuration {0}")]
    ConfigurationError(#[from] config::ConfigError),
    #[error("general IO error: {0}")]
    IO(#[from] io::Error),
    #[error("yaml parse error: {0}")]
    Yaml(#[from] serde_yaml::Error),
    #[error("webserver error: {0}")]
    Webserver(#[from] hyper::Error),
    #[error("tokio thread error: {0}")]
    TokioThread(#[from] tokio::task::JoinError),
    #[error("auth token not present")]
    TokenNotPresent,
    #[error("websocket error {0}")]
    Websocket(#[from] tokio_tungstenite::tungstenite::Error),
    #[error("mpsc channel send error {0}")]
    Mpsc(#[from] tokio::sync::mpsc::error::SendError<connection::ChannelMessage>),
    #[error("uploader error: {0}")]
    Uploader(#[from] UploaderError),
}
