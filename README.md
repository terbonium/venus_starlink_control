# Starlink D-Bus Service for VenusOS

A D-Bus service that exposes Starlink dish status and control on VenusOS systems (Cerbo GX, Venus GX, etc.).

## Features

- **Status Monitoring**: Real-time dish status including throughput, latency, GPS, orientation
- **Dish Control**: Reboot, stow/unstow, and snow melt (ice) mode control
- **D-Bus Integration**: Native VenusOS integration via system D-Bus

## Installation

1. Copy the project to your VenusOS device:
   ```bash
   scp -r venus_starlink_control root@<device-ip>:/data/
   ```

2. Run the installer:
   ```bash
   ssh root@<device-ip>
   cd /data/venus_starlink_control
   ./install.sh
   ```

## D-Bus Interface

### Service Name
```
com.victronenergy.starlink
```

### Status Paths (Read-Only)

| Path | Description |
|------|-------------|
| `/Connected` | Connection status (0=disconnected, 1=connected) |
| `/State` | Dish state code |
| `/StateText` | Dish state as text |
| `/DownlinkThroughput` | Download speed (Mbps) |
| `/UplinkThroughput` | Upload speed (Mbps) |
| `/PopPingLatencyMs` | Latency (ms) |
| `/PopPingDropRate` | Packet drop rate |
| `/Obstructed` | Currently obstructed (0/1) |
| `/ObstructedPercent` | Obstruction percentage |
| `/Uptime` | Dish uptime (seconds) |
| `/Gps/Valid` | GPS fix valid (0/1) |
| `/Gps/Latitude` | GPS latitude |
| `/Gps/Longitude` | GPS longitude |
| `/Gps/Altitude` | GPS altitude (m) |
| `/Attitude/Heading` | GPS heading (degrees) |
| `/Attitude/Tilt` | Dish tilt angle (degrees) |
| `/Alerts/IsHeating` | Snow melt active (0/1) |
| `/Alerts/ThermalThrottle` | Thermal throttling (0/1) |

### Control Path (Write)

Write values to `/Command` to control the dish:

| Value | Action |
|-------|--------|
| 1 | Reboot dish |
| 2 | Stow dish |
| 3 | Unstow dish |
| 4 | Snow melt OFF |
| 5 | Snow melt ON (force) |
| 6 | Snow melt AUTO |

### Command Result

Read `/CommandResult` after sending a command:
- 0 = No command sent
- 1 = Success
- 2 = Failed

## Usage Examples

### Read dish status
```bash
# Get connection status
dbus -y com.victronenergy.starlink /Connected GetValue

# Get current throughput
dbus -y com.victronenergy.starlink /DownlinkThroughput GetValue
dbus -y com.victronenergy.starlink /UplinkThroughput GetValue

# Get GPS position
dbus -y com.victronenergy.starlink /Gps/Latitude GetValue
dbus -y com.victronenergy.starlink /Gps/Longitude GetValue
```

### Control the dish
```bash
# Reboot dish
dbus -y com.victronenergy.starlink /Command SetValue %1

# Stow dish
dbus -y com.victronenergy.starlink /Command SetValue %2

# Unstow dish
dbus -y com.victronenergy.starlink /Command SetValue %3

# Turn on snow melt (ice mode)
dbus -y com.victronenergy.starlink /Command SetValue %5

# Turn off snow melt
dbus -y com.victronenergy.starlink /Command SetValue %4
```

## Configuration

Edit `/data/venus_starlink_control/config/starlink.conf`:

```bash
# Dish address (IP:port)
DISH_ADDRESS="192.168.100.1:9200"

# Status update interval in milliseconds
UPDATE_INTERVAL=5000

# Enable debug logging (0 or 1)
DEBUG=0

# Enable mock mode for testing without dish (0 or 1)
MOCK_MODE=0
```

## Service Management

```bash
# Start service
svc -u /service/starlink-dbus

# Stop service
svc -d /service/starlink-dbus

# Restart service
svc -t /service/starlink-dbus

# Check status
svstat /service/starlink-dbus

# View logs
cat /service/starlink-dbus/log/main/current
```

## File Structure

```
venus_starlink_control/
├── README.md
├── install.sh              # Installation script
├── uninstall.sh            # Uninstallation script
├── config/
│   └── starlink.conf       # Configuration file
├── proto/
│   └── spacex/api/device/
│       ├── common.proto    # Common protobuf definitions
│       ├── device.proto    # Device API definitions
│       └── dish.proto      # Dish-specific definitions
└── dbus-service/
    ├── starlink_dbus_service.py  # Main D-Bus service
    ├── starlink_grpc_client.py   # gRPC client for Starlink
    └── run                       # daemontools run script
```

## Uninstallation

```bash
./uninstall.sh
```

## Requirements

- VenusOS 2.80 or later
- Network connection to Starlink dish (default: 192.168.100.1:9200)
- Python 3 with grpcio

## Network Setup

The Starlink dish must be reachable from your VenusOS device. Typical setup:
- Starlink dish: 192.168.100.1
- VenusOS device connected to Starlink network or routed appropriately

## License

MIT License
