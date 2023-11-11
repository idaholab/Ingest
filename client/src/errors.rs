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
    #[error("unknown client error")]
    Unknown,
}
