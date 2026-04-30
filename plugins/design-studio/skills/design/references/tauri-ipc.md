# Rust ↔ Frontend Communication in Tauri v2

## Commands (Frontend → Rust, with return value)

### Rust

```rust
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

#[tauri::command]
async fn fetch_data(db: tauri::State<'_, Database>) -> Result<Vec<Item>, String> {
    db.get_items().await.map_err(|e| e.to_string())
}

tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![greet, fetch_data])
```

### Frontend

```typescript
import { invoke } from '@tauri-apps/api/core'; // NOT @tauri-apps/api/tauri (that's v1!)

const greeting = await invoke<string>('greet', { name: 'World' });
const items = await invoke<Item[]>('fetch_data');
```

## Events (Bidirectional, fire-and-forget)

### Rust → Frontend

```rust
app.emit("download-complete", DownloadPayload { path: "/tmp/file.pdf" })?;
```

```typescript
import { listen } from '@tauri-apps/api/event';
const unlisten = await listen<DownloadPayload>('download-complete', (event) => {
    console.log('Downloaded:', event.payload.path);
});
unlisten();
```

### Frontend → Rust

```typescript
import { emit } from '@tauri-apps/api/event';
await emit('user-action', { type: 'click', target: 'button' });
```

```rust
app.listen("user-action", |event| {
    println!("User action: {:?}", event.payload());
});
```

## Channels (Streaming, ordered, fast)

For progress updates, real-time data, stdout streaming:

```rust
use tauri::ipc::Channel;

#[derive(Clone, serde::Serialize)]
struct Progress { percent: u32, message: String }

#[tauri::command]
async fn download(url: String, on_progress: Channel<Progress>) -> Result<String, String> {
    for i in 0..=100 {
        on_progress.send(Progress { percent: i, message: format!("{}%", i) }).unwrap();
    }
    Ok("done".into())
}
```

```typescript
import { invoke, Channel } from '@tauri-apps/api/core';

const onProgress = new Channel<Progress>();
onProgress.onmessage = (p) => console.log(`${p.percent}%`);
await invoke('download', { url: '...', onProgress });
```

## Capabilities (Permissions)

Tauri v2 denies everything by default. Create capability files:

```json
// src-tauri/capabilities/default.json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "windows": ["main"],
  "permissions": ["core:default", "core:event:default", "opener:default", "store:default"]
}
```

For mobile-specific:
```json
// src-tauri/capabilities/mobile.json
{
  "$schema": "../gen/schemas/mobile-schema.json",
  "identifier": "mobile",
  "platforms": ["iOS", "android"],
  "windows": ["main"],
  "permissions": ["haptics:default", "biometric:default"]
}
```
