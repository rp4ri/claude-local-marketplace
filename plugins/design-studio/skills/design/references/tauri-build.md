# Tauri v2 Android Build, Sign & Release

## Build Commands

```bash
# Debug APK (auto-signed with debug key, for testing)
pnpm tauri android build --apk --debug

# Release APK (unsigned — needs signing)
pnpm tauri android build --apk

# AAB for Google Play Store
pnpm tauri android build -- --aab
```

Output locations:
- Debug: `src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk`
- Release (unsigned): `src-tauri/gen/android/app/build/outputs/apk/universal/release/app-universal-release-unsigned.apk`
- Release (signed): `src-tauri/gen/android/app/build/outputs/apk/universal/release/app-universal-release.apk`

### Target-specific builds

```bash
# Single architecture (faster, smaller APK ~24MB vs ~96MB)
pnpm tauri android build --apk --target aarch64

# All architectures (default)
pnpm tauri android build --apk
```

Prefer `--target aarch64` for dev/testing releases. Use universal only for final distribution.

## ADB Install

```bash
adb install -r path/to/app.apk
```

**Note**: Unsigned release APKs fail with `INSTALL_PARSE_FAILED_NO_CERTIFICATES`. Use debug builds for testing, or sign the release APK.

## Signing a Release APK

### 1. Create Keystore

```bash
keytool -genkey -v -keystore release.keystore -alias my-app \
  -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Create `keystore.properties`

At `src-tauri/gen/android/keystore.properties` (NEVER commit this):

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=my-app
storeFile=/absolute/path/to/release.keystore
```

### 3. Configure Gradle

In `src-tauri/gen/android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            props.load(java.io.FileInputStream(rootProject.file("keystore.properties")))
            storeFile = file(props["storeFile"] as String)
            storePassword = props["storePassword"] as String
            keyAlias = props["keyAlias"] as String
            keyPassword = props["keyPassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. Build Signed APK

```bash
pnpm tauri android build --apk
```

## App Icon Generation

```bash
pnpm tauri icon ./source-icon.png
```

For Android, ensure the icon has padding (adaptive icon masking crops edges).

## Common Build Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `NDK_HOME not set` | NDK path not configured | `export NDK_HOME=$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk/ \| head -1)` |
| `class file major version 67` | Wrong Java version | Tauri v2 requires JDK 17 |
| `-lgcc` linking error | NDK 23+ removed `libgcc` | Use NDK 25+ which maps `-lgcc` to `-lunwind` |
| OpenSSL build failures | Missing system OpenSSL | Add `openssl = { version = "0.10", features = ["vendored"] }` to Cargo.toml |
