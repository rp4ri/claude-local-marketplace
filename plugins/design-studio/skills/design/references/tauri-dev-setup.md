# Tauri v2 Android Development on ARM64 EC2

Setup guide for developing Tauri v2 Android apps on an ARM64 (aarch64) EC2 instance, testing on a physical Android phone connected to a local Mac via USB, tunneled through SSH.

## Architecture

```
Samsung S24 Ultra (USB cable)
      |
      v
MacBook (adb server on port 5037)
      |
      v  SSH tunnel: -R 5037:localhost:5037 (ADB protocol)
      |             -L 1420:localhost:1420 (Vite dev server)
      v
ARM64 EC2 Instance
      |
      v
cargo tauri android dev / Vite dev server (port 1420)
```

## Quick Start (environment already set up)

```bash
# Mac: connect phone, open SSH with tunnels
adb devices
ssh -R 5037:localhost:5037 -L 1420:localhost:1420 your-ec2-alias

# EC2: verify phone, set reverse, start dev
adb devices
adb reverse tcp:1420 tcp:1420
adb reverse tcp:1421 tcp:1421
pnpm tauri android dev
```

## EC2 Setup From Scratch

### 1. Java + Android SDK

```bash
sudo apt install openjdk-17-jdk -y

mkdir -p $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip -d $HOME/android-sdk/cmdline-tools
mv $HOME/android-sdk/cmdline-tools/cmdline-tools $HOME/android-sdk/cmdline-tools/latest

export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

sdkmanager "platform-tools" "platforms;android-34" "build-tools;35.0.0"
```

### 2. SnowNF NDK r29 (ARM64-native NDK)

Google does NOT provide an ARM64 Linux NDK. Use the SnowNF community build.

```bash
wget https://github.com/nicebug/snowNF-ndk/releases/download/r29/android-ndk-r29-linux-aarch64.tar.gz
tar xzf android-ndk-r29-linux-aarch64.tar.gz -C $HOME/android-sdk/ndk/
mv $HOME/android-sdk/ndk/android-ndk-r29 $HOME/android-sdk/ndk/r29
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/r29
```

**Requires Ubuntu 24.04+** (GLIBC 2.39). Ubuntu 22.04 (GLIBC 2.35) is too old.

**libxml2 dependency**: SnowNF's `ld.lld` needs `libxml2.so.16`:
```bash
wget https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.6.tar.xz
tar xf libxml2-2.13.6.tar.xz && cd libxml2-2.13.6
./configure --prefix=/usr/local && make -j$(nproc) && sudo make install
sudo ln -sf /usr/local/lib/libxml2.so.2.13.6 /usr/lib/aarch64-linux-gnu/libxml2.so.16
```

### 3. x86_64 emulation (for AAPT2)

```bash
sudo apt install qemu-user-static binfmt-support -y
sudo dpkg --add-architecture amd64

# IMPORTANT: Use archive.ubuntu.com for amd64 (NOT ports.ubuntu.com)
sudo tee /etc/apt/sources.list.d/amd64-archive.list << 'EOF'
deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
EOF

sudo apt update
sudo apt install libc6:amd64 libstdc++6:amd64 zlib1g:amd64 -y
```

### 4. Rust + Android target

```bash
rustup target add aarch64-linux-android
cargo install tauri-cli --version "^2.0"
```

## ADB Tunnel Setup

### Two SSH tunnels needed

| Tunnel | Direction | Purpose |
|--------|-----------|---------|
| `-R 5037:localhost:5037` | EC2 → Mac | ADB protocol: EC2 can control the phone |
| `-L 1420:localhost:1420` | Mac → EC2 | Vite dev server: phone reaches EC2's Vite via Mac relay |

### Why `-L 1420` is needed

`adb reverse tcp:1420 tcp:1420` forwards the phone's localhost:1420 to the **Mac** (where ADB server runs), NOT to the EC2. The `-L` tunnel relays Mac:1420 → EC2:1420 where Vite actually runs.

### IDE port conflicts

If another IDE (Android Studio, Antigravity) occupies port 5037, use a custom port:
```bash
# Mac
ANDROID_ADB_SERVER_PORT=15037 adb -P 15037 start-server
ssh -R 15037:localhost:15037 -L 1420:localhost:1420 your-ec2-alias

# EC2
ANDROID_ADB_SERVER_PORT=15037 adb -P 15037 devices
```

## Troubleshooting

### "Failed to request http://172.31.x.x:1420/" on phone

Tauri bakes the EC2's private IP into the compiled Rust binary. The phone can't reach VPC IPs. Fix with binary patching:

```bash
SO_FILE="src-tauri/target/aarch64-linux-android/debug/lib<app>_lib.so"

python3 -c "
with open('$SO_FILE', 'rb') as f: data = f.read()
old = b'172.31.x.x'       # replace with your EC2 IP (find with: strings $SO_FILE | grep 172.31)
new = b'127.000.000.1'    # MUST be same byte length
data = data.replace(old, new)
with open('$SO_FILE', 'wb') as f: f.write(data)
"

cd src-tauri/gen/android && ./gradlew assembleArm64Debug -x rustBuildArm64Debug
adb install -r app/build/outputs/apk/arm64/debug/app-arm64-debug.apk
adb reverse tcp:1420 tcp:1420
```

**CRITICAL**: Replacement IP MUST be exact same byte length. Use leading zeros (`127.000.000.1`). NEVER use null bytes — crashes the app.

### Other common issues

| Problem | Fix |
|---------|-----|
| `Exec format error` from NDK | Install SnowNF NDK (ARM64-native) |
| `AAPT2 daemon startup failed` | Install qemu-user-static + amd64 libs |
| `libxml2.so.16 not found` | Build libxml2 from source + symlink |
| GLIBC too old | Upgrade to Ubuntu 24.04 |
| Empty `adb devices` on EC2 | Kill stray EC2 adb daemon: `ss -tlnp \| grep 5037` |
| `Empty reply from server` from phone | Add `-L 1420:localhost:1420` to SSH |
| App crash after binary patch | Used null bytes — repatch with leading-zero IP |
