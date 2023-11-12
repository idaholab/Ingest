mod config;
mod errors;
mod webserver;

use tray_icon::{
    menu::{AboutMetadata, Menu, MenuEvent, MenuItem, PredefinedMenuItem},
    TrayIconBuilder, TrayIconEvent,
};
use winit::event_loop::{ControlFlow, EventLoopBuilder};

use crate::errors::ClientError;
use crate::webserver::boot_webserver;
use chrono::Local;
use std::path::Path;

#[tokio::main]
async fn main() -> Result<(), ClientError> {
    // First let's pull in the current configuration - this will automatically create a hardware_id
    // if one does not exist for this client
    let client_config = config::get_configuration()?;
    let icon = load_icon(Path::new("icon.png"));

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

    let event_loop = EventLoopBuilder::new().build().unwrap();
    let menu = Menu::new();
    let mut menu_status = MenuItem::new("Connected", false, None);
    menu.append(&menu_status);
    menu.append(&MenuItem::new("Reconnect", true, None));

    // we will spin up a separate thread for the websocket connections and axum webserver here
    tokio::spawn(async move { boot_webserver(client_config.clone()).await });

    #[cfg(not(target_os = "linux"))]
    let mut tray_icon = Some(
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
        menu_status.set_text(format!("Connected - {}", time.format("%Y-%m-%d %H:%M:%S")));

        if let Ok(event) = tray_channel.try_recv() {
            println!("{event:?}");
        }

        if let Ok(event) = menu_channel.try_recv() {
            println!("{event:?}");
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
