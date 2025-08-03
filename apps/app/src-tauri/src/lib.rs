#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      
      // Window configuration
      use tauri::Manager;
      let window = app.get_webview_window("main").unwrap();
      
      #[cfg(target_os = "macos")]
      {
        use window_vibrancy::{apply_vibrancy, NSVisualEffectMaterial};
        
        // Apply vibrancy effect
        apply_vibrancy(&window, NSVisualEffectMaterial::HudWindow, None, Some(16.0))
          .expect("Unsupported platform! 'apply_vibrancy' is only supported on macOS");
      }
      
      #[cfg(target_os = "windows")]
      {
        use window_vibrancy::apply_blur;
        
        apply_blur(&window, Some((18, 18, 18, 125)))
          .expect("Unsupported platform! 'apply_blur' is only supported on Windows");
      }

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
