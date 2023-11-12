use crate::config::ClientConfiguration;
use crate::errors::ClientError;
use axum::response::Html;
use axum::routing::get;
use axum::Router;
use handlebars::Handlebars;
use rust_embed::RustEmbed;
use serde::{Deserialize, Serialize};
use serde_json::json;
use uuid::Uuid;

#[derive(RustEmbed)]
#[folder = "./templates/"]
struct Templates;

#[derive(Serialize, Deserialize)]
struct RegisterFill {
    register_url: String,
}

impl RegisterFill {
    fn new(config: ClientConfiguration) -> Self {
        RegisterFill {
            register_url: format!(
                "{}/hardware_register?hardware_id={}" // eventually we should add dynamic port and callbacks
                config.ingest_server.unwrap_or(String::new()),
                config.hardware_id.unwrap_or(Uuid::new_v4())
            ),
        }
    }
}

pub async fn boot_webserver(config: ClientConfiguration) -> Result<(), ClientError> {
    // pull in the handlebars templates and get them registered - we're using rust-embed to make
    // sure they're in our binary so we don't have to do anything weird with packaging
    let mut reg = Handlebars::new();

    // because the embedded webserver is such an essential part of the system, we're fine crashing
    // and burning on failure here, fail fast and hard
    reg.register_embed_templates::<Templates>()
        .expect("unable to load embedded templates for webserver");

    // our app needs basically three routes - the register gives a redirect, a home route,
    // and a callback route that the central server sends the user back to with a token to be exchanged/stored
    // for authentication purposes and the websocket connection,
    let main = reg
        .render("register.hbs", &json!(RegisterFill::new(config)))
        .expect("unable to render webserver template");
    let app = Router::new().route("/", get(|| async { Html(main) }));

    axum::Server::bind(&"0.0.0.0:8097".parse().unwrap())
        .serve(app.into_make_service())
        .await?;

    Ok(())
}
