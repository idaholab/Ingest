mod config;
mod connection;
mod errors;
mod tests;
mod uploader;
mod webserver;

use tray_icon::{
    menu::{Menu, MenuEvent, MenuItem},
    TrayIconBuilder, TrayIconEvent,
};
use winit::event_loop::{ControlFlow, EventLoopBuilder};

use crate::connection::make_connection_thread;
use crate::errors::ClientError;
use crate::webserver::boot_webserver;
use chrono::{Local, Utc};
use notify_rust::{Notification, Timeout};
use std::path::Path;
use std::process;
use std::sync::{Arc, Mutex};
use tracing::{error, Level};
use tracing_subscriber::FmtSubscriber;
use uuid::Uuid;

pub struct Connected(bool);

#[tokio::main]
async fn main() -> Result<(), ClientError> {
    // a builder for `FmtSubscriber`.
    let subscriber = FmtSubscriber::builder()
        // all spans/events with a level higher than TRACE (e.g, debug, info, warn, etc.)
        // will be written to stdout.
        .with_max_level(Level::TRACE)
        // completes the builder.
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    // First let's pull in the current configuration - this will automatically create a hardware_id
    // if one does not exist for this client
    let client_config = config::get_configuration()?;

    let register_url = format!(
        "http://{}/dashboard/destinations/client/register_client?client_id={}", // eventually we should add dynamic port and callbacks
        client_config.ingest_server.unwrap_or_default(),
        client_config.hardware_id.unwrap_or(Uuid::new_v4())
    );

    let icon = load_icon(Path::new("./assets/icon.png"));

    // we have to use a standard mutex so we can do a blocking read in the event loop - it's a pain in the ass
    let semaphore = Arc::new(Mutex::new(Connected(false)));
    let webserver_semaphore = semaphore.clone();
    let connected_semaphore = semaphore.clone();

    // we will spin up separate threads for the websocket connections and axum webserver here
    // note that the connection thread _might_ die here if the token isn't available or is invalid
    // that's ok - the webserver thread can spin this up or the user can spin this up via the menu
    tokio::spawn(async move { boot_webserver(webserver_semaphore).await });
    // TODO: Add reconnection and exponential backoff to the make connection task eventually so we can have fault tolerance and no manual user interaction
    tokio::spawn(async move { make_connection_thread(connected_semaphore).await });

    // now let's set up the system tray and get the event loop running
    #[cfg(target_os = "linux")]
    // on linux we have to start up gtk and the system try in a separate thread
    std::thread::spawn(|| {
        use tray_icon::menu::Menu;

        gtk::init().unwrap();
        let _tray_icon = TrayIconBuilder::new()
            .with_menu(Box::new(Menu::new()))
            .with_icon(icon)
            .build()
            .unwrap();

        gtk::main();
    });

    let not_authenticated = match client_config.token_expires_at {
        None => true,
        Some(e) => Utc::now().date_naive() > e && client_config.token.is_some(),
    };

    if not_authenticated {
        let _ = Notification::new()
            .summary("Ingest")
            .body("You must authenticate with Ingest website before you can use the Ingest application.")
            .timeout(Timeout::Milliseconds(6000)) //milliseconds
            .show();
    }

    let event_loop = EventLoopBuilder::new().build().unwrap();
    let menu = Menu::new();
    let menu_authenticate = MenuItem::new("Authenticate with Ingest", true, None);
    let menu_status = MenuItem::new("Disconnected", false, None);
    let menu_reconnect = MenuItem::new("Reconnect", true, None);
    let menu_exit = MenuItem::new("Exit", true, None);

    if not_authenticated {
        match menu.insert(&menu_authenticate, 0) {
            Ok(_) => {}
            Err(_) => {
                error!("unable to append the authentication menu item");
                process::exit(1);
            }
        }
    }

    menu.append_items(&[&menu_status, &menu_reconnect, &menu_exit])
        .expect("unable to register menu item");

    #[cfg(not(target_os = "linux"))]
    let tray_icon = Some(
        TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip("winit - awesome windowing lib")
            .with_icon(icon)
            .build()
            .unwrap(),
    );

    let menu_channel = MenuEvent::receiver();
    let tray_channel = TrayIconEvent::receiver();

    let _ = event_loop.run(move |_event, event_loop| {
        let time = Local::now();
        event_loop.set_control_flow(ControlFlow::Poll);

        {
            if semaphore.lock().unwrap().0 {
                menu_status.set_text(format!("Connected - {}", time.to_rfc2822()));
            } else {
                menu_status.set_text("Disconnected");
            }
        }

        if let Ok(_event) = tray_channel.try_recv() {}

        if let Ok(event) = menu_channel.try_recv() {
            {
                if event.id == menu_reconnect.id() && !semaphore.lock().unwrap().0 {
                    let new_semaphore = semaphore.clone();
                    tokio::spawn(async move { make_connection_thread(new_semaphore).await });
                }

                if event.id == menu_exit.id() {
                    process::exit(0);
                }

                if event.id == menu_authenticate.id() {
                    match open::that(register_url.as_str()) {
                        Ok(_) => {}
                        Err(e) => error!("unable to open register URL on user's system {:?}", e),
                    }
                }
            }
        }
    });

    Ok(())
}

fn load_icon(path: &std::path::Path) -> tray_icon::Icon {
    let (icon_rgba, icon_width, icon_height) = {
        let image = image::open(path)
            .expect("Failed to open icon path")
            .into_rgba8();
        let (width, height) = image.dimensions();
        let rgba = image.into_raw();
        (rgba, width, height)
    };
    tray_icon::Icon::from_rgba(icon_rgba, icon_width, icon_height).expect("Failed to open icon")
}
