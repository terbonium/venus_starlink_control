# Venus Starlink Control

A VenusOS GUI-v2 plugin for monitoring and controlling Starlink satellite dishes.

## Features

- **Web Dashboard**: Browser-accessible dashboard at `http://<device-ip>:8088`
  - Works from any device on the network (phone, tablet, computer)
  - Auto-updating display (2-second refresh)
  - Mobile-friendly responsive design

- **Status Monitoring**: View real-time Starlink dish statistics including:
  - Connection state and uptime
  - Signal quality (SNR)
  - Download/Upload throughput
  - Latency (ping)
  - Obstruction status
  - Hardware/Software information
  - GPS location (latitude, longitude, altitude)
  - Dish orientation (heading, tilt, roll)

- **Dish Control**:
  - Reboot the dish
  - Stow/Unstow the dish

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       VenusOS GX Device                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐       ┌──────────────────────────┐         │
│  │   GUI-v2 Plugin │◄─────►│  D-Bus (com.victronenergy│         │
│  │   (QML Pages)   │       │  .starlink)              │         │
│  │ [Local Display] │       └────────────┬─────────────┘         │
│  └─────────────────┘                    │                       │
│                                         │                       │
│  ┌─────────────────┐       ┌────────────▼─────────────┐         │
│  │  Web Dashboard  │◄─────►│  starlink-dbus-service   │         │
│  │  (port 8088)    │       │  (Python gRPC Client)    │         │
│  │ [Browser Access]│       └────────────┬─────────────┘         │
│  └─────────────────┘                    │                       │
│                                         │                       │
└─────────────────────────────────────────┼───────────────────────┘
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
├── web-dashboard/
│   ├── starlink_web_server.py    # Web server for browser access
│   ├── index.html                # Dashboard HTML/CSS/JS
│   └── run                       # daemontools run script
├── gui-v2/
│   └── plugin.json               # Generated plugin manifest
└── gui-v2-source/
    ├── PageStarlinkSettings.qml  # Main settings page
    └── PageStarlinkStatus.qml    # Detailed status page
```

## D-Bus Interface

The service exposes data on `com.victronenergy.starlink`:

### Status & Performance

| Path | Type | Description |
|------|------|-------------|
| `/Connected` | int | Connection to dish (0=Disconnected, 1=Connected) |
| `/State` | int | Dish state (0=Unknown, 1=Connected, 2=Booting, 3=Searching, 4=Stowed, etc.) |
| `/StateText` | string | Human-readable state description |
| `/Uptime` | int | Dish uptime in seconds |
| `/DownlinkThroughput` | float | Download speed in Mbps |
| `/UplinkThroughput` | float | Upload speed in Mbps |
| `/PopPingLatencyMs` | float | Latency to PoP in milliseconds |
| `/PopPingDropRate` | float | Packet drop rate (0-1) |
| `/Obstructed` | int | Obstruction status (0=Clear, 1=Obstructed) |
| `/ObstructedPercent` | float | Percentage of time obstructed |
| `/FractionObstructed` | float | Fraction of sky obstructed |

### GPS Location

| Path | Type | Description |
|------|------|-------------|
| `/Gps/Valid` | int | GPS fix status (0=No fix, 1=Valid) |
| `/Gps/Satellites` | int | Number of GPS satellites in view |
| `/Gps/Latitude` | float | Latitude in decimal degrees |
| `/Gps/Longitude` | float | Longitude in decimal degrees |
| `/Gps/Altitude` | float | Altitude in meters |

### Attitude / Orientation

| Path | Type | Description |
|------|------|-------------|
| `/Attitude/Heading` | float | GPS heading (COG) in degrees |
| `/Attitude/Tilt` | float | Tilt from vertical in degrees |
| `/Attitude/Roll` | float | Roll angle in degrees |
| `/Attitude/Azimuth` | float | Boresight azimuth in degrees |
| `/Attitude/Elevation` | float | Boresight elevation in degrees |
| `/Attitude/Speed` | float | GPS speed in m/s |

### Device Information

| Path | Type | Description |
|------|------|-------------|
| `/DeviceId` | string | Dish device ID |
| `/HardwareVersion` | string | Hardware revision |
| `/SoftwareVersion` | string | Current software version |
| `/CountryCode` | string | Country code |
| `/Bootcount` | int | Number of times dish has booted |

### Alerts

| Path | Type | Description |
|------|------|-------------|
| `/Alerts/ThermalThrottle` | int | Thermal throttling active (0/1) |
| `/Alerts/ThermalShutdown` | int | Thermal shutdown active (0/1) |
| `/Alerts/MotorsStuck` | int | Motors stuck alert (0/1) |
| `/Alerts/MastNotVertical` | int | Mast not vertical alert (0/1) |
| `/Alerts/SlowEthernet` | int | Slow ethernet alert (0/1) |
| `/Alerts/Roaming` | int | Roaming active (0/1) |
| `/Alerts/IsHeating` | int | Dish heating active (0/1) |
| `/Alerts/PowerSaveIdle` | int | Power save idle mode (0/1) |

### Commands

| Path | Type | Description |
|------|------|-------------|
| `/Command` | int | Write to issue commands (1=Reboot, 2=Stow, 3=Unstow) |
| `/CommandResult` | int | Result of last command (0=None, 1=Success, 2=Failed) |

## Web Dashboard API

The web dashboard exposes a REST API for integration:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Dashboard HTML page |
| `/api/status` | GET | JSON object with all Starlink status data |
| `/api/command` | POST | Send command to dish (JSON body: `{"command": 1\|2\|3}`) |

Command values: 1=Reboot, 2=Stow, 3=Unstow

Example:
```bash
# Get status
curl http://<device-ip>:8088/api/status

# Stow the dish
curl -X POST -H "Content-Type: application/json" \
  -d '{"command": 2}' http://<device-ip>:8088/api/command
```

## License

MIT License
