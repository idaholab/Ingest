#[cfg(test)]
mod uploader_tests {
    use crate::connection::{ChannelMessage, MessageType};
    use crate::uploader::UploaderError::{Internal, NotImplemented};
    use crate::uploader::{Uploader, UploaderError};
    use serde_json::Value::Null;
    use std::path::PathBuf;
    use std::str::FromStr;
    use std::time::Duration;
    use tokio::time::sleep;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_init_uploader() -> Result<(), UploaderError> {
        let id = Uuid::new_v4();
        let file_path = PathBuf::from_str("./test_files/test.csv").unwrap();
        let (tx, _rx) = tokio::sync::mpsc::unbounded_channel::<ChannelMessage>();

        Uploader::new(id, file_path, tx).await?;
        Ok(())
    }

    #[tokio::test]
    // we're testing that the uploader successfully asks to join the topic for its upload id - once
    // we join, we expect a message that will kick off the upload. We don't want to start until the
    // server is ready
    async fn test_join_message() -> Result<(), UploaderError> {
        let id = Uuid::new_v4();
        let file_path = PathBuf::from_str("./test_files/test.csv").unwrap();
        let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<ChannelMessage>();

        let uploader = Uploader::new(id, file_path, tx).await?;
        // now we join the phoenix channel necessary
        uploader.request_join_channel().await?;

        match rx.recv().await {
            // note that we should only be getting one msg here - so if it's not ours, it'll break
            None => return Err(UploaderError::Internal("no message received".into())),
            Some(m) => {
                assert_eq!(m.3, MessageType::Join);
                Ok(())
            }
        }
    }

    #[tokio::test]
    // testing that once we're a part of a channel we can request status and have that passed into
    // the websocket receiving channel
    async fn test_status_message() -> Result<(), UploaderError> {
        let id = Uuid::new_v4();
        let file_path = PathBuf::from_str("./test_files/test.csv").unwrap();
        let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<ChannelMessage>();

        let uploader = Uploader::new(id, file_path, tx).await?;
        // now we join the phoenix channel necessary
        uploader.request_join_channel().await?;

        let join_msg = match rx.recv().await {
            // note that we should only be getting one msg here - so if it's not ours, it'll break
            None => return Err(UploaderError::Internal("no message received".into())),
            Some(m) => m,
        };

        // we pretend we got the reply back and are in the channel, so we trigger confirmation on the
        // uploader
        uploader
            .handle_msg(ChannelMessage(
                join_msg.0,
                join_msg.1,
                join_msg.2,
                MessageType::Reply,
                Null,
            ))
            .await?;
        uploader.request_status().await?;
        // sleep for just a second so we don't race on the status message being sent from the thread
        sleep(Duration::from_secs(2)).await;

        let mut seen_status = false;
        let mut msgs = Vec::new();
        rx.recv_many(&mut msgs, 1).await;

        for msg in msgs {
            let result = match msg.3 {
                MessageType::Status => {
                    // we're not checking the uploader functionality here, just the fact it'll send
                    // the status
                    seen_status = true;
                    Ok(())
                }
                // we might accidentally get the join message here, you never know, so handle it
                MessageType::Join => Ok(()),
                _ => Err(NotImplemented),
            };

            result?;
        }

        if seen_status {
            Ok(())
        } else {
            Err(Internal("No status message sent".into()))
        }
    }
}
