mod config;
mod errors;

use crate::errors::ClientError;
use uuid::Uuid;

#[tokio::main]
async fn main() -> Result<(), ClientError> {
    // First let's pull in the current configuration - this will automatically create a hardware_id
    // if one does not exist for this client
    let client_config = config::get_configuration()?;

    println!("{:?}", client_config);
    Ok(())
}
