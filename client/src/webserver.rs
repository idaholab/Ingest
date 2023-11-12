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
// we're going to keep all the variables for the three pages in the same struct because it doesn't
// make sense to build a different struct for each page when it's at most one or two things and we
// don't plan on using this UI for anything more than registration and possible status
struct PageVariables {
    register_url: String,
}

impl PageVariables {
    fn new(config: ClientConfiguration) -> Self {
        PageVariables {
            register_url: format!(
                "{}/dashboard/destinations/register_client?client_id={}", // eventually we should add dynamic port and callbacks
                config.ingest_server.unwrap_or(String::new()),
                config.hardware_id.unwrap_or(Uuid::new_v4())
            ),
        }
    }
}

pub async fn boot_webserver(config: ClientConfiguration) -> Result<(), ClientError> {
    let app = Router::new().route(
        "/",
        get(|| async move {
            // pull in the handlebars templates and get them registered - we're using rust-embed to make
            // sure they're in our binary so we don't have to do anything weird with packaging - we could
            // do this outside of the function but in case we wanted to add an updated status we need
            // to do this each time as Handlebars::Registry isn't Send for some godawful reason
            let mut reg = Handlebars::new();

            // because the embedded webserver is such an essential part of the system, we're fine crashing
            // and burning on failure here, fail fast and hard
            reg.register_embed_templates::<Templates>()
                .expect("unable to load embedded templates for webserver");

            // our app needs basically three routes - the register gives a redirect, a home route,
            // and a callback route that the central server sends the user back to with a token to be exchanged/stored
            // for authentication purposes and the websocket connection,
            let vars = PageVariables::new(config.clone());
            let register_page = reg
                .render("register.hbs", &json!(vars))
                .expect("unable to render webserver template");

            let main_page = reg
                .render("main.hbs", &json!(vars))
                .expect("unable to render webserver template");

            match config.token {
                None => Html(register_page),
                Some(_) => Html(main_page),
            }
        }),
    );

    // 8097 because hopefully nothing else is running on that port TODO: make port dynamic
    axum::Server::bind(&"0.0.0.0:8097".parse().unwrap())
        .serve(app.into_make_service())
        .await?;

    Ok(())
}
