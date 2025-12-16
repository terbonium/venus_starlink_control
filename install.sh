#!/bin/bash
#
# Starlink Control Plugin Installation Script for VenusOS
#
# This script installs and configures the Starlink control plugin
# including the D-Bus service and GUI-v2 UI components.
#

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
APP_NAME="starlink-control"
APP_DIR="${SCRIPT_DIR}"
ENABLED_DIR="/data/apps/enabled"
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

# Compile GUI-v2 plugin
compile_gui_plugin() {
    echo_info "Compiling GUI-v2 plugin..."

    COMPILER="/opt/victronenergy/gui-v2/gui-v2-plugin-compiler.py"

    if [ ! -f "${COMPILER}" ]; then
        echo_warn "GUI-v2 plugin compiler not found at ${COMPILER}"
        echo_warn "Skipping GUI plugin compilation"
        return 0
    fi

    cd "${APP_DIR}"

    # Compile the settings page for the Integrations menu
    # Format: --settings "QmlFile.qml:MenuLabel"
    python3 "${COMPILER}" \
        --name "${APP_NAME}" \
        --min-required-version "v3.70" \
        --settings "PageStarlinkSettings.qml:Starlink" || {
            echo_error "Failed to compile GUI plugin"
            return 1
        }

    echo_info "GUI plugin compiled successfully"
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

# Enable the app
enable_app() {
    echo_info "Enabling app..."

    # Create enabled symlink
    mkdir -p "${ENABLED_DIR}"
    ln -sf "${APP_DIR}" "${ENABLED_DIR}/${APP_NAME}"

    echo_info "App enabled"
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
            echo_info "Service started successfully"
        else
            echo_warn "Service may not have started. Check logs at ${SERVICE_DIR}/log/main/"
        fi
    else
        echo_warn "svc command not found, please start the service manually"
    fi
}

# Main installation
main() {
    echo ""
    echo "=========================================="
    echo "  Starlink Control Plugin Installer"
    echo "=========================================="
    echo ""

    check_venus_version
    install_dependencies
    generate_protos
    create_config
    compile_gui_plugin
    setup_service
    enable_app
    start_service

    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""
    echo "The Starlink plugin has been installed."
    echo ""
    echo "Configuration file: ${APP_DIR}/config/starlink.conf"
    echo "Service logs: ${SERVICE_DIR}/log/main/"
    echo ""
    echo "To access the plugin:"
    echo "  Settings -> Integrations -> Starlink"
    echo ""
    echo "Service management:"
    echo "  Start:   svc -u ${SERVICE_DIR}"
    echo "  Stop:    svc -d ${SERVICE_DIR}"
    echo "  Restart: svc -t ${SERVICE_DIR}"
    echo "  Status:  svstat ${SERVICE_DIR}"
    echo ""
}

main "$@"
