# Tauri v2 Plugins Reference

## Installation Pattern

All official plugins follow: Cargo `tauri-plugin-{name}`, npm `@tauri-apps/plugin-{name}`.

```toml
# src-tauri/Cargo.toml
[dependencies]
tauri-plugin-{name} = "2"
```

```bash
pnpm add @tauri-apps/plugin-{name}
```

```rust
// src-tauri/src/lib.rs
tauri::Builder::default()
    .plugin(tauri_plugin_{name}::init())
```

```json
// src-tauri/capabilities/default.json
{ "permissions": ["core:default", "{name}:default"] }
```

## Official Plugins — Mobile Compatible

| Plugin | Key APIs |
|--------|----------|
| **barcode-scanner** | `scan()`, `cancel()` |
| **biometric** | `authenticate()`, `isAvailable()` |
| **clipboard-manager** | `readText()`, `writeText()` |
| **deep-link** | `onOpenUrl()`, `getCurrent()` |
| **dialog** | `open()`, `save()`, `message()`, `ask()` |
| **fs** | `readTextFile()`, `writeTextFile()`, `exists()` |
| **geolocation** | `getCurrentPosition()`, `watchPosition()` |
| **haptics** | `vibrate()`, `impactFeedback()` |
| **http** | `fetch()` — bypasses CORS |
| **log** | `info()`, `warn()`, `error()`, `debug()` |
| **nfc** | `read()`, `write()` |
| **notification** | `sendNotification()`, `requestPermission()` |
| **opener** | `openUrl()`, `openPath()` |
| **os** | `platform()`, `version()`, `arch()`, `locale()` |
| **process** | `exit()`, `relaunch()` |
| **sql** | `execute()`, `select()` |
| **store** | `get()`, `set()`, `delete()` |
| **stronghold** | IOTA Stronghold encrypted storage |
| **upload** | `upload()` with progress |
| **websocket** | `connect()`, `send()`, `onMessage()` |

## Official Plugins — Desktop Only

autostart, cli, global-shortcut, localhost, persisted-scope, positioner, shell, single-instance, updater, window-state

## Community Plugins

| Plugin | Description |
|--------|-------------|
| `tauri-plugin-safe-area-insets` (ronickg) | JS API for safe area insets |
| `tauri-plugin-safe-area-insets-css` (saurL) | Auto CSS vars for safe area |
| `tauri-plugin-camera` | Android camera |
| `tauri-plugin-apple-camera` | iOS camera |
| `tauri-plugin-iap` | In-app purchases (iOS StoreKit 2 + Android Play Billing) |
| `tauri-plugin-pliap` | Cross-platform purchases |
| `tauri-plugin-app-events` (wtto00) | App backgrounded/foregrounded |
| `tauri-plugin-cors-fetch` (idootop) | Bypass CORS from WebView |
| `tauri-plugin-widgets` (s00d) | Android Glance home screen widgets |
