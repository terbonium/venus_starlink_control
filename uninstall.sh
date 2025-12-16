#!/bin/bash
#
# Starlink Control Plugin Uninstallation Script for VenusOS
#

set -e

# Configuration
APP_NAME="starlink-control"
APP_DIR="/data/apps/available/${APP_NAME}"
ENABLED_DIR="/data/apps/enabled"
SERVICE_DIR="/service/starlink-dbus"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

echo ""
echo "=========================================="
echo "  Starlink Control Plugin Uninstaller"
echo "=========================================="
echo ""

# Stop the service
echo_info "Stopping service..."
if [ -d "${SERVICE_DIR}" ]; then
    svc -d "${SERVICE_DIR}" 2>/dev/null || true
    sleep 1
fi

# Remove service directory
echo_info "Removing service..."
rm -rf "${SERVICE_DIR}"

# Remove enabled symlink
echo_info "Disabling app..."
rm -f "${ENABLED_DIR}/${APP_NAME}"

# Optionally remove app directory
read -p "Remove app files from ${APP_DIR}? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Removing app files..."
    rm -rf "${APP_DIR}"
    echo_info "App files removed"
else
    echo_info "App files preserved at ${APP_DIR}"
fi

echo ""
echo "=========================================="
echo "  Uninstallation Complete!"
echo "=========================================="
echo ""
