mod config;
mod errors;
use tray_icon::{
    menu::{AboutMetadata, Menu, MenuEvent, MenuItem, PredefinedMenuItem},
    TrayIconBuilder, TrayIconEvent,
};
use winit::event_loop::{ControlFlow, EventLoopBuilder};

use crate::errors::ClientError;
use std::path::Path;

#[tokio::main]
async fn main() -> Result<(), ClientError> {
    // First let's pull in the current configuration - this will automatically create a hardware_id
    // if one does not exist for this client
    let client_config = config::get_configuration()?;
    let icon = load_icon(Path::new("icon.png"));

    #[cfg(target_os = "linux")]
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
    menu.append(&MenuItem::new("Menu item #2", true, None));

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
        event_loop.set_control_flow(ControlFlow::Poll);

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
