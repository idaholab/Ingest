use crate::config::ClientConfiguration;
use crate::errors::ClientError;
use axum::extract::State;
use axum::response::Html;
use axum::routing::get;
use axum::Router;
use handlebars::Handlebars;
use rust_embed::RustEmbed;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::sync::Arc;
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

struct PageState<'a> {
    config: ClientConfiguration,
    handlebars: handlebars::Handlebars<'a>,
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
    let mut reg = Handlebars::new();

    // because the embedded webserver is such an essential part of the system, we're fine crashing
    // and burning on failure here, fail fast and hard
    reg.register_embed_templates::<Templates>()
        .expect("unable to load embedded templates for webserver");

    let state = Arc::new(PageState {
        config,
        handlebars: reg,
    });

    let app = Router::new()
        .route("/", get(main))
        .route("/callback", get(callback))
        .with_state(state);

    // 8097 because hopefully nothing else is running on that port TODO: make port dynamic
    axum::Server::bind(&"0.0.0.0:8097".parse().unwrap())
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn main<'a>(State(state): State<Arc<PageState<'a>>>) -> Html<String> {
    let vars = PageVariables::new(state.config.clone());
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

async fn callback<'a>(State(state): State<Arc<PageState<'a>>>) -> Html<String> {
    let vars = PageVariables::new(state.config.clone());
    let callback_page = state
        .handlebars
        .render("callback.hbs", &json!(vars))
        .expect("unable to render webserver template");

    Html(callback_page)
}
