# Venus Starlink Control

A VenusOS GUI-v2 plugin for monitoring and controlling Starlink satellite dishes.

## Features

- **Status Monitoring**: View real-time Starlink dish statistics including:
  - Connection state and uptime
  - Signal quality (SNR)
  - Download/Upload throughput
  - Latency (ping)
  - Obstruction status
  - Hardware/Software information

- **Dish Control**:
  - Reboot the dish
  - Stow/Unstow the dish

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     VenusOS GX Device                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐       ┌──────────────────────────┐    │
│  │   GUI-v2 Plugin │◄─────►│  D-Bus (com.victronenergy│    │
│  │   (QML Pages)   │       │  .starlink)              │    │
│  └─────────────────┘       └────────────┬─────────────┘    │
│                                         │                   │
│                            ┌────────────▼─────────────┐    │
│                            │  starlink-dbus-service   │    │
│                            │  (Python gRPC Client)    │    │
│                            └────────────┬─────────────┘    │
└─────────────────────────────────────────┼───────────────────┘
                                          │ gRPC (port 9200)
                              ┌───────────▼───────────┐
                              │   Starlink Dish       │
                              │   (192.168.100.1)     │
                              └───────────────────────┘
```

## Requirements

- Venus OS v3.70~45 or newer
- Python 3 with:
  - `dbus-python`
  - `grpcio`
  - `grpcio-tools`
- Network access to Starlink dish (typically 192.168.100.1:9200)

## Installation

1. Copy the app to the GX device:
   ```bash
   scp -r . root@<gx-ip>:/data/apps/available/starlink-control/
   ```

2. Run the install script on the GX device:
   ```bash
   ssh root@<gx-ip>
   cd /data/apps/available/starlink-control
   ./install.sh
   ```

3. The install script will:
   - Install Python dependencies
   - Generate protobuf files
   - Compile the GUI-v2 plugin
   - Enable the app
   - Start the D-Bus service

## Manual Setup

### Generate Protobuf Files
```bash
cd /data/apps/available/starlink-control
python3 -m grpc_tools.protoc -I./proto --python_out=./dbus-service --grpc_python_out=./dbus-service ./proto/*.proto
```

### Compile GUI Plugin
```bash
python3 /opt/victronenergy/gui-v2/gui-v2-plugin-compiler.py \
  --name starlink-control \
  --min-required-version v3.70 \
  --settings PageStarlinkSettings.qml 'Starlink'
```

### Enable the App
```bash
ln -sf /data/apps/available/starlink-control /data/apps/enabled/starlink-control
```

### Start the Service
```bash
svc -u /service/starlink-dbus
```

## File Structure

```
starlink-control/
├── README.md
├── install.sh                    # Installation script
├── proto/
│   └── spacex/api/device/
│       ├── common.proto          # Common Starlink protobuf definitions
│       ├── device.proto          # Device API definitions
│       └── dish.proto            # Dish-specific definitions
├── dbus-service/
│   ├── starlink_dbus_service.py  # Main D-Bus service
│   ├── starlink_grpc_client.py   # gRPC client for Starlink
│   └── run                       # daemontools run script
├── gui-v2/
│   └── plugin.json               # Generated plugin manifest
└── gui-v2-source/
    ├── PageStarlinkSettings.qml  # Main settings page
    └── PageStarlinkStatus.qml    # Detailed status page
```

## D-Bus Interface

The service exposes data on `com.victronenergy.starlink`:

| Path | Type | Description |
|------|------|-------------|
| `/State` | int | Connection state (0=Unknown, 1=Connected, 2=Searching, etc.) |
| `/Uptime` | int | Dish uptime in seconds |
| `/DownlinkThroughput` | float | Download speed in Mbps |
| `/UplinkThroughput` | float | Upload speed in Mbps |
| `/PopPingLatencyMs` | float | Latency to PoP in milliseconds |
| `/SignalQuality` | float | Signal quality (0-1) |
| `/Obstructed` | int | Obstruction status (0=Clear, 1=Obstructed) |
| `/ObstructedPercent` | float | Percentage of time obstructed |
| `/HardwareVersion` | string | Hardware revision |
| `/SoftwareVersion` | string | Current software version |
| `/DeviceId` | string | Dish device ID |
| `/Command` | int | Write to issue commands (1=Reboot, 2=Stow, 3=Unstow) |

## License

MIT License
