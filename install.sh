#!/bin/bash
#
# Starlink D-Bus Service Installation Script for VenusOS
#
# This script installs the Starlink D-Bus service which exposes
# dish status and control (reboot, stow, ice mode) on the system bus.
#

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
APP_NAME="starlink-control"
APP_DIR="${SCRIPT_DIR}"
SERVICE_DIR="/service/starlink-dbus"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo_error "Please run as root"
    exit 1
fi

# Check VenusOS version
check_venus_version() {
    echo_info "Checking VenusOS version..."

    if [ -f /opt/victronenergy/version ]; then
        VERSION=$(cat /opt/victronenergy/version)
        echo_info "VenusOS version: ${VERSION}"
    else
        echo_warn "Could not determine VenusOS version"
    fi
}

# Install Python dependencies
install_dependencies() {
    echo_info "Installing Python dependencies..."

    # Check if pip is available
    if command -v pip3 &> /dev/null; then
        pip3 install grpcio grpcio-tools --quiet || {
            echo_warn "Could not install Python packages via pip"
            echo_warn "Please ensure grpcio and grpcio-tools are available"
        }
    else
        echo_warn "pip3 not found, skipping Python package installation"
        echo_warn "Please install grpcio and grpcio-tools manually"
    fi
}

# Generate protobuf files
generate_protos() {
    echo_info "Generating protobuf files..."

    cd "${APP_DIR}"

    # Create output directory
    mkdir -p "${APP_DIR}/dbus-service/spacex/api/device"

    # Generate Python files from protos
    python3 -m grpc_tools.protoc \
        -I./proto \
        --python_out=./dbus-service \
        --grpc_python_out=./dbus-service \
        ./proto/spacex/api/device/*.proto || {
            echo_error "Failed to generate protobuf files"
            echo_warn "The service will run in mock mode without protobuf support"
        }

    # Create __init__.py files for Python packages
    touch "${APP_DIR}/dbus-service/spacex/__init__.py"
    touch "${APP_DIR}/dbus-service/spacex/api/__init__.py"
    touch "${APP_DIR}/dbus-service/spacex/api/device/__init__.py"

    echo_info "Protobuf files generated"
}

# Setup daemontools service
setup_service() {
    echo_info "Setting up D-Bus service..."

    # Create service directory
    mkdir -p "${SERVICE_DIR}"

    # Create run script symlink
    ln -sf "${APP_DIR}/dbus-service/run" "${SERVICE_DIR}/run"

    # Make run script executable
    chmod +x "${APP_DIR}/dbus-service/run"

    # Create log directory
    mkdir -p "${SERVICE_DIR}/log"

    # Create log run script
    cat > "${SERVICE_DIR}/log/run" << 'EOF'
#!/bin/sh
exec svlogd -tt ./main
EOF
    chmod +x "${SERVICE_DIR}/log/run"

    echo_info "D-Bus service configured"
}

# Create default configuration
create_config() {
    echo_info "Creating default configuration..."

    CONFIG_DIR="${APP_DIR}/config"
    mkdir -p "${CONFIG_DIR}"

    if [ ! -f "${CONFIG_DIR}/starlink.conf" ]; then
        cat > "${CONFIG_DIR}/starlink.conf" << 'EOF'
# Starlink Control Configuration
#
# Dish address (IP:port)
DISH_ADDRESS="192.168.100.1:9200"

# Status update interval in milliseconds
UPDATE_INTERVAL=5000

# Enable debug logging (0 or 1)
DEBUG=0

# Enable mock mode for testing without dish (0 or 1)
MOCK_MODE=0
EOF
        echo_info "Default configuration created at ${CONFIG_DIR}/starlink.conf"
    else
        echo_info "Configuration file already exists, skipping"
    fi
}

# Start the service
start_service() {
    echo_info "Starting Starlink D-Bus service..."

    # Use svc to start the service
    if command -v svc &> /dev/null; then
        svc -u "${SERVICE_DIR}" 2>/dev/null || true
        sleep 2

        # Check if service is running
        if svstat "${SERVICE_DIR}" 2>/dev/null | grep -q "up"; then
            echo_info "D-Bus service started successfully"
        else
            echo_warn "D-Bus service may not have started. Check logs at ${SERVICE_DIR}/log/main/"
        fi
    else
        echo_warn "svc command not found, please start the services manually"
    fi
}

# Main installation
main() {
    echo ""
    echo "=========================================="
    echo "  Starlink D-Bus Service Installer"
    echo "=========================================="
    echo ""

    check_venus_version
    install_dependencies
    generate_protos
    create_config
    setup_service
    start_service

    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""
    echo "The Starlink D-Bus service has been installed."
    echo ""
    echo "Configuration file: ${APP_DIR}/config/starlink.conf"
    echo "Service logs: ${SERVICE_DIR}/log/main/"
    echo ""
    echo "D-Bus Service: com.victronenergy.starlink"
    echo ""
    echo "D-Bus Paths (readable):"
    echo "  /Connected           - Connection status (0/1)"
    echo "  /State               - Dish state"
    echo "  /StateText           - Dish state as text"
    echo "  /DownlinkThroughput  - Download speed (Mbps)"
    echo "  /UplinkThroughput    - Upload speed (Mbps)"
    echo "  /PopPingLatencyMs    - Latency (ms)"
    echo "  /Obstructed          - Obstruction status (0/1)"
    echo "  /Gps/Latitude        - GPS latitude"
    echo "  /Gps/Longitude       - GPS longitude"
    echo "  /Alerts/*            - Various alert flags"
    echo ""
    echo "D-Bus Control (write to /Command):"
    echo "  1 = Reboot dish"
    echo "  2 = Stow dish"
    echo "  3 = Unstow dish"
    echo "  4 = Ice/Snow melt OFF"
    echo "  5 = Ice/Snow melt ON (force)"
    echo "  6 = Ice/Snow melt AUTO"
    echo ""
    echo "Service management:"
    echo "  Start:   svc -u ${SERVICE_DIR}"
    echo "  Stop:    svc -d ${SERVICE_DIR}"
    echo "  Restart: svc -t ${SERVICE_DIR}"
    echo "  Status:  svstat ${SERVICE_DIR}"
    echo ""
    echo "Example D-Bus commands:"
    echo "  dbus -y com.victronenergy.starlink /Connected GetValue"
    echo "  dbus -y com.victronenergy.starlink /Command SetValue %1  # Reboot"
    echo ""
}

main "$@"
