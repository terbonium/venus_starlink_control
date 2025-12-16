# Venus OS GUI v2 WASM Builder

This directory contains everything needed to build a custom Venus OS GUI v2 WASM binary with the Starlink integration, using Docker.

## Prerequisites

- Docker installed and running
- SSH access to your Cerbo (for deployment)
- VenusOS with GUI v2 enabled on your device

## Quick Start

### Build Only

```bash
./build.sh
```

This will:
1. Build a Docker image with Qt 6.5.3 LTS, Emscripten 3.1.37, and all dependencies
2. Clone the official gui-v2 repository
3. Apply Starlink patches and QML pages
4. Compile the WASM binary
5. Output files to `./output/`

### Build and Deploy

```bash
./build.sh --deploy 192.168.1.100
```

Replace `192.168.1.100` with your Cerbo's IP address.

### Deploy Existing Build

```bash
./build.sh --deploy-only 192.168.1.100
```

## Build Options

| Option | Description |
|--------|-------------|
| `--deploy <ip>` | Build and deploy to Cerbo at specified IP |
| `--deploy-only <ip>` | Deploy existing build without rebuilding |
| `--rebuild` | Force rebuild of Docker image |
| `--shell` | Open interactive shell in build container |
| `--help` | Show help message |

## Output Files

After a successful build, the `./output/` directory will contain:

```
output/
├── venus-gui-v2.wasm        # Uncompressed WASM binary
├── venus-gui-v2.wasm.gz     # Gzipped WASM binary (deployed)
├── venus-gui-v2.js          # JavaScript loader
├── qtloader.js              # Qt loader script
├── venus-gui-v2.wasm.sha256 # Checksum
├── venus-gui-v2.wasm.gz.sha256
└── index.html               # Standalone test page
```

## Build Time

The first build will take **30-60 minutes** as it needs to:
- Download and install Qt 6.5.3 LTS (~2GB)
- Download and install Emscripten
- Build the QtMqtt module
- Compile gui-v2 to WASM

Subsequent builds will be faster if the Docker image is cached.

## Customization

### Adding More QML Pages

Add your QML files to `patches/qml/Victron/VenusOS/pages/settings/`

### Modifying Existing Pages

Create patch files in `patches/` directory. Patches are applied automatically during build.

### Changing Qt/Emscripten Versions

Edit the `Dockerfile` and update:
```dockerfile
# Note: Qt and Emscripten versions must be compatible
# See Qt documentation for supported emsdk versions
ENV QT_VERSION=6.5.3
# Then update the base image tag in FROM emscripten/emsdk:X.X.XX
```

## Deployment Details

The deploy script:
1. Tests SSH connection to Cerbo
2. Backs up existing WASM files (with `--backup`)
3. Copies new WASM files to `/var/www/venus/gui-v2/`
4. Verifies checksums
5. Restarts GUI service (with `--restart`)

### SSH Access

Make sure your Cerbo has SSH enabled:
1. Settings → General → Access Level → Superuser
2. Settings → General → SSH → Enable

### Manual Deployment

If automatic deployment fails, you can manually copy files:

```bash
scp output/venus-gui-v2.wasm.gz root@<cerbo-ip>:/var/www/venus/gui-v2/
scp output/venus-gui-v2.js root@<cerbo-ip>:/var/www/venus/gui-v2/
```

Then restart the GUI:
```bash
ssh root@<cerbo-ip> "svc -t /service/start-gui"
```

## Troubleshooting

### Build Fails

1. Make sure Docker has enough memory (at least 4GB)
2. Check Docker disk space
3. Try `./build.sh --rebuild` to recreate the image

### Deployment Fails

1. Verify SSH access: `ssh root@<cerbo-ip>`
2. Check VenusOS version supports GUI v2
3. Ensure GUI v2 is enabled in device settings

### Starlink Menu Not Visible

The Starlink menu only appears when the D-Bus service is running:
```bash
ssh root@<cerbo-ip> "svstat /service/starlink-dbus"
```

### Changes Not Visible in Browser

1. Clear browser cache (Ctrl+Shift+R)
2. Wait up to 10 minutes for VRM sync
3. Try a different browser

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Container                      │
├─────────────────────────────────────────────────────────┤
│  emscripten/emsdk:3.1.37 (based on Ubuntu)             │
│  ├── Qt 6.5.3 LTS (desktop + wasm_singlethread)        │
│  ├── Emscripten 3.1.37                                 │
│  ├── QtMqtt module                                      │
│  └── gui-v2 source + Starlink patches                  │
├─────────────────────────────────────────────────────────┤
│                         ↓                               │
│              WASM Build (ninja)                         │
│                         ↓                               │
│              output/venus-gui-v2.wasm.gz               │
└─────────────────────────────────────────────────────────┘
                          │
                          │ SCP
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Cerbo GX                             │
├─────────────────────────────────────────────────────────┤
│  /var/www/venus/gui-v2/                                │
│  └── venus-gui-v2.wasm.gz  (custom build)              │
└─────────────────────────────────────────────────────────┘
```

## References

- [Venus OS GUI v2 Wiki](https://github.com/victronenergy/gui-v2/wiki)
- [How to Build GUI v2](https://github.com/victronenergy/gui-v2/wiki/How-to-build-venus-gui-v2)
- [Victron Community](https://community.victronenergy.com)
