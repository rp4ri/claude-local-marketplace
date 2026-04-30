# Android Issues in Tauri v2

## Status Bar, Safe Area & Keyboard Insets

### Problem

`env(safe-area-inset-top)` returns `0` in Tauri's Android WebView. Content overlaps the status bar and navigation bar because `enableEdgeToEdge()` draws behind system bars. Additionally, the virtual keyboard covers input fields because `enableEdgeToEdge()` calls `setDecorFitsSystemWindows(false)`, which disables automatic keyboard resize.

### Solution: Native Kotlin Padding (systemBars + IME)

In `src-tauri/gen/android/app/src/main/java/com/YOUR/app/MainActivity.kt`:

```kotlin
package com.your.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : TauriActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, windowInsets ->
            val systemBars = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            val ime = windowInsets.getInsets(WindowInsetsCompat.Type.ime())
            view.setPadding(
                systemBars.left,
                systemBars.top,
                systemBars.right,
                maxOf(systemBars.bottom, ime.bottom)
            )
            WindowInsetsCompat.CONSUMED
        }
    }
}
```

**CRITICAL**: Always include `WindowInsetsCompat.Type.ime()` alongside `systemBars()`. Without it, the keyboard will cover input fields. Use `maxOf(systemBars.bottom, ime.bottom)` — when keyboard is open, `ime.bottom` is the keyboard height (~300px+); when closed, `systemBars.bottom` is the nav bar (~48px).

Also add to AndroidManifest.xml on the `<activity>` tag:
```xml
android:windowSoftInputMode="adjustResize"
```

### Alternative: CSS Variable Injection

Inject inset values from Kotlin into CSS variables for frontend control:

```kotlin
ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, windowInsets ->
    val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
    val density = resources.displayMetrics.density
    val topDp = insets.top / density
    val bottomDp = insets.bottom / density
    val webView = view.findViewById<android.webkit.WebView>(android.R.id.content)
    webView?.evaluateJavascript(
        "document.documentElement.style.setProperty('--safe-area-inset-top', '${topDp}px');" +
        "document.documentElement.style.setProperty('--safe-area-inset-bottom', '${bottomDp}px');",
        null
    )
    windowInsets
}
```

Then use: `padding-top: var(--safe-area-inset-top, 0px);`

### Alternative: Community Plugin

- `tauri-plugin-safe-area-insets` (ronickg) — JS API: `getInsets()` → `{ top, bottom, left, right }`
- `tauri-plugin-safe-area-insets-css` (saurL) — Auto-sets CSS vars

---

## Horizontal Overflow

Android WebView expands to fit the widest element, ignoring `overflow-x: hidden`.

### Fix

```css
* {
  max-width: 100vw;
  box-sizing: border-box;
}

.katex-display, .katex {
  overflow-x: auto;
  max-width: 100% !important;
}

pre, code {
  overflow-x: auto;
  max-width: 100% !important;
}

table {
  display: block;
  overflow-x: auto;
  max-width: 100%;
}

img {
  max-width: 100%;
  height: auto;
}
```

Common offenders: KaTeX blocks, `<pre>` code blocks, wide tables, images, elements with negative margins.

---

## Third-Party Cookies

`fetch()` from `tauri.localhost` to an external API sets cookies on the external domain — blocked as third-party cookies.

**Solutions:**
1. OAuth: Navigate WebView to backend directly (see tauri-oauth reference)
2. API auth: Use Bearer tokens instead of cookies
3. Persistent data: Use `tauri-plugin-store` or `tauri-plugin-sql`

---

## WebView Debugging

### Logcat

```bash
adb logcat -s "Tauri/Console:*"           # WebView console.log
adb logcat | grep -i "tauri\|yourapp"     # All Tauri logs
adb logcat -c && sleep 10 && adb logcat -d -s "Tauri/Console:*"  # Fresh capture
```

### Chrome DevTools

1. Enable USB debugging on device
2. Open `chrome://inspect/#devices` in desktop Chrome
3. Click "inspect" on the WebView (debug builds only)

---

## Back Button

Back button exits app instead of navigating SPA history. Add to `tauri.conf.json`:

```json
{ "app": { "onBackButtonPress": "navigateBack" } }
```

---

## CSP (Content Security Policy)

```json
{
  "app": {
    "security": {
      "csp": "default-src 'self' https://tauri.localhost; connect-src 'self' https://tauri.localhost https://your-api.com; style-src 'self' https://tauri.localhost 'unsafe-inline'; img-src 'self' https://tauri.localhost https: data:; font-src 'self' https://tauri.localhost data:"
    }
  }
}
```

Common mistakes: forgetting `https://tauri.localhost`, missing `'unsafe-inline'` for styles, missing `data:` for fonts.

---

## CORS from tauri.localhost

Backend must handle CORS for Tauri origins:

```typescript
const CORS_ORIGINS = new Set([
  'tauri://localhost',
  'https://tauri.localhost',
]);

if (CORS_ORIGINS.has(origin)) {
  response.headers.set('Access-Control-Allow-Origin', origin);
  response.headers.set('Access-Control-Allow-Credentials', 'true');
}
```

Also add to auth library's `trustedOrigins`.

---

## Known Issues

- **SDK 35**: Edge-to-edge is mandatory on Android 15, `windowOptOutEdgeToEdgeEnforcement` deprecated
- **Keyboard overlap**: `visualViewport` API does NOT work correctly in Tauri Android WebView (Tauri issues #7868, #10631). Do NOT use `visualViewport` for keyboard handling — use native IME insets in `MainActivity.kt` instead.
- **`adjustResize` alone is NOT enough**: When `enableEdgeToEdge()` is active, it calls `setDecorFitsSystemWindows(false)` which disables automatic resize. You MUST handle IME insets manually in Kotlin.
- **`h-dvh` unreliable**: CSS `dvh` units depend on the WebView correctly reporting dynamic viewport height, which doesn't work if the native layer doesn't resize the WebView. Fix the native insets first.

## What Does NOT Work (Don't Waste Time)

These approaches were all tested and failed in Tauri Android WebView:

| Approach | Why It Fails |
|----------|-------------|
| `env(safe-area-inset-top)` | Returns `0` in Android WebView (Chromium bug) |
| `visualViewport` API | Broken in Tauri Android WebView (issues #7868, #10631) |
| `fitsSystemWindows=true` in XML | Overridden by `enableEdgeToEdge()` |
| `windowSoftInputMode="adjustResize"` alone | No effect when edge-to-edge is active |
| CSS `dvh` units alone | WebView doesn't resize without native IME handling |
| `position: absolute` + JS offset | Unreliable, race conditions |
| Hardcoded `calc(100dvh - Npx)` | The N is a guess, breaks on different devices |
