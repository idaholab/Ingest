use crate::errors::ClientError;
use config::Config;
use serde::{Deserialize, Serialize};
use std::fs::OpenOptions;
use uuid::Uuid;

#[derive(Serialize, Deserialize, Clone)]
pub struct ClientConfiguration {
    pub hardware_id: Option<Uuid>,
    pub ingest_server: Option<String>,
    pub token: Option<String>,
    pub token_expires_at: Option<chrono::NaiveDate>,
}

pub fn get_configuration() -> Result<ClientConfiguration, ClientError> {
    let settings = Config::builder()
        .add_source(config::File::with_name(".ingest_client_config").required(false))
        .add_source(config::Environment::with_prefix("INGEST_CLIENT"))
        .build()?;

    let mut config = settings.try_deserialize::<ClientConfiguration>()?;

    match config.ingest_server {
        None => config.ingest_server = Some(String::from("localhost:4000")),
        Some(_) => {}
    }

    match config.hardware_id {
        // if we don't have a hardware id set, then we need to generate and write one for this client
        None => {
            let hardware_id = Uuid::new_v4();
            config.hardware_id = Some(hardware_id);

            config.write_to_host()?;
        }
        Some(_) => {}
    }

    Ok(config)
}

impl ClientConfiguration {
    pub fn write_to_host(&self) -> Result<(), ClientError> {
        let file = OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(".ingest_client_config.yml")?;

        serde_yaml::to_writer(file, self)?;
        Ok(())
    }
}
