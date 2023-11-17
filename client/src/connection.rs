use crate::config::get_configuration;
use crate::errors::ClientError;
use crate::Connected;
use std::sync::Arc;
use tokio::sync::RwLock;

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
    Ok(())
}
