// Custom commands for file operations
#[tauri::command]
async fn load_project_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(&path)
        .map_err(|e| format!("Failed to load project file {}: {}", path, e))
}

#[tauri::command]
async fn save_project_file(path: String, contents: String) -> Result<(), String> {
    std::fs::write(&path, contents)
        .map_err(|e| format!("Failed to save project file {}: {}", path, e))
}

#[tauri::command]
async fn check_project_exists(path: String) -> Result<bool, String> {
    Ok(std::path::Path::new(&path).exists())
}

#[tauri::command]
async fn save_export_file(path: String, contents: String) -> Result<(), String> {
    std::fs::write(&path, contents)
        .map_err(|e| format!("Failed to save export file {}: {}", path, e))
}

#[tauri::command]
async fn save_export_file_base64(path: String, content: String) -> Result<(), String> {
    use base64::{engine::general_purpose, Engine as _};

    let decoded = general_purpose::STANDARD
        .decode(&content)
        .map_err(|e| format!("Failed to decode base64 content: {}", e))?;

    std::fs::write(&path, decoded)
        .map_err(|e| format!("Failed to save export file {}: {}", path, e))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            load_project_file,
            save_project_file,
            check_project_exists,
            save_export_file,
            save_export_file_base64
        ])
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
