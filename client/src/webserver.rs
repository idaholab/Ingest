use crate::config::{get_configuration, ClientConfiguration};
use crate::connection::make_connection_thread;
use crate::errors::ClientError;
use crate::Connected;
use axum::extract::{Query, State};
use axum::response::Html;
use axum::routing::get;
use axum::Router;
use chrono::{Days, Utc};
use handlebars::Handlebars;
use rust_embed::RustEmbed;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::collections::HashMap;
use std::ops::Add;
use std::sync::{Arc, Mutex};
use tracing::info;
use uuid::Uuid;

#[derive(RustEmbed)]
#[folder = "./templates/"]
struct Templates;

#[derive(Serialize, Deserialize)]
// we're going to keep all the variables for the three pages in the same struct because it doesn't
// make sense to build a different struct for each page when it's at most one or two things, and we
// don't plan on using this UI for anything more than registration and possible status
struct PageVariables {
    register_url: String,
    error_message: Option<String>,
    success_message: Option<String>,
    connected: Option<bool>,
}

struct PageState<'a> {
    config: ClientConfiguration,
    handlebars: handlebars::Handlebars<'a>,
    connected: Arc<Mutex<Connected>>,
}

impl PageVariables {
    fn new(config: ClientConfiguration) -> Self {
        PageVariables {
            register_url: format!(
                "http://{}/dashboard/destinations/client/register_client?client_id={}", // eventually we should add dynamic port and callbacks
                config.ingest_server.unwrap_or_default(),
                config.hardware_id.unwrap_or(Uuid::new_v4())
            ),
            error_message: None,
            success_message: None,
            connected: None,
        }
    }
}

pub async fn boot_webserver(semaphore: Arc<Mutex<Connected>>) -> Result<(), ClientError> {
    let config = get_configuration()?;
    let mut reg = Handlebars::new();

    // because the embedded webserver is such an essential part of the system, we're fine crashing
    // and burning on failure here, fail fast and hard
    reg.register_embed_templates::<Templates>()
        .expect("unable to load embedded templates for webserver");

    let state = Arc::new(PageState {
        config,
        handlebars: reg,
        connected: semaphore,
    });

    let app = Router::new()
        .route("/", get(main))
        .route("/callback", get(callback))
        .with_state(state);

    // 8097 because hopefully nothing else is running on that port TODO: make port dynamic
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8097").await?;
    axum::serve(listener, app).await?;
    Ok(())
}

async fn main<'a>(State(state): State<Arc<PageState<'a>>>) -> Html<String> {
    let mut vars = PageVariables::new(state.config.clone());
    vars.connected = Some(state.connected.lock().unwrap().0);

    // if disconnected - let's book up a thread and run the connection
    if !state.connected.lock().unwrap().0 {
        info!("websocket wasn't connected on refresh, connecting");
        let semaphore = state.connected.clone();
        tokio::spawn(async move { make_connection_thread(semaphore).await });
    }

    let register_page = state
        .handlebars
        .render("register.hbs", &json!(vars))
        .expect("unable to render webserver template");

    let main_page = state
        .handlebars
        .render("main.hbs", &json!(vars))
        .expect("unable to render webserver template");

    match state.config.token {
        None => Html(register_page),
        Some(_) => Html(main_page),
    }
}

async fn callback<'a>(
    Query(params): Query<HashMap<String, String>>,
    State(state): State<Arc<PageState<'a>>>,
) -> Html<String> {
    let mut vars = PageVariables::new(state.config.clone());

    match params.get("token") {
        None => {
            vars.error_message = Some(String::from(
                "No token present in callback, try registering again",
            ));

            let error_page = state
                .handlebars
                .render("register.hbs", &json!(vars))
                .expect("unable to render webserver template");

            Html(error_page)
        }
        Some(token) => {
            // if we have the token, attempt a websocket connection with it, if it succeeds we know
            // we have a valid token - break this websocket connection after and inform the user they
            // need to restart after writing the token to the config file
            let result = match &state.config.ingest_server {
                None => {
                    tokio_tungstenite::connect_async(format!(
                        "ws://localhost:4000/client/websocket?vsn=2.0.0&token={}",
                        token
                    ))
                    .await
                }
                Some(url) => {
                    tokio_tungstenite::connect_async(format!(
                        "ws://{}/client/websocket?vsn=2.0.0&token={}",
                        url, token
                    ))
                    .await
                }
            };

            match result {
                Ok((mut ws, _)) => {
                    // don't need to keep this open
                    ws.close(None).await.unwrap();

                    let mut config = state.config.clone();
                    config.token = Some(token.clone());

                    // Ingest should default to 10 days expiry, so if we don't have it set that
                    config.token_expires_at = match params.get("expires_at") {
                        None => Some(Utc::now().date_naive().add(Days::new(10))),
                        Some(expires) => Some(
                            chrono::NaiveDate::parse_from_str(expires, "%Y%m%d").unwrap_or(Utc::now().date_naive().add(Days::new(10)))
                        ),
                    };

                    config
                        .write_to_host()
                        .expect("unable to write the token to the host configuration file");

                    vars.success_message = Some(String::from(
                        "Successfully registered client. Restart Required",
                    ));

                    let error_page = state
                        .handlebars
                        .render("main.hbs", &json!(vars))
                        .expect("unable to render webserver template");

                    Html(error_page)
                }
                Err(e) => {
                    vars.error_message = Some(e.to_string());

                    let error_page = state
                        .handlebars
                        .render("register.hbs", &json!(vars))
                        .expect("unable to render webserver template");

                    Html(error_page)
                }
            }
        }
    }
}
