#!/bin/bash
#
# Deploy Venus OS GUI v2 WASM to remote Cerbo
#
# Usage: ./deploy.sh <cerbo-ip> [--backup] [--restart]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Default paths
OUTPUT_DIR="${OUTPUT_DIR:-/build/output}"
REMOTE_GUI_PATH="/var/www/venus/gui-v2"
REMOTE_USER="root"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"

# Parse arguments
CERBO_IP=""
DO_BACKUP=0
DO_RESTART=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            DO_BACKUP=1
            shift
            ;;
        --restart)
            DO_RESTART=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <cerbo-ip> [--backup] [--restart]"
            echo ""
            echo "Options:"
            echo "  --backup   Backup existing WASM files before deployment"
            echo "  --restart  Restart GUI service after deployment"
            echo ""
            exit 0
            ;;
        *)
            CERBO_IP="$1"
            shift
            ;;
    esac
done

if [ -z "${CERBO_IP}" ]; then
    echo_error "Usage: $0 <cerbo-ip> [--backup] [--restart]"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Venus OS GUI v2 WASM Deployment"
echo "=========================================="
echo ""
echo "Target: ${REMOTE_USER}@${CERBO_IP}"
echo ""

# Check if output files exist
if [ ! -f "${OUTPUT_DIR}/venus-gui-v2.wasm.gz" ]; then
    echo_error "WASM file not found at ${OUTPUT_DIR}/venus-gui-v2.wasm.gz"
    echo_error "Please run the build first."
    exit 1
fi

# Test SSH connection
echo_info "Testing SSH connection..."
if ! ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "echo 'Connection OK'" 2>/dev/null; then
    echo_error "Cannot connect to ${CERBO_IP}"
    echo_error "Make sure SSH is enabled and root access is available."
    echo ""
    echo "To enable SSH on VenusOS:"
    echo "  1. Go to Settings -> General -> Access Level"
    echo "  2. Set to 'Superuser'"
    echo "  3. Go to Settings -> General -> SSH"
    echo "  4. Enable SSH"
    exit 1
fi

# Check VenusOS version
echo_info "Checking VenusOS version..."
VENUS_VERSION=$(ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "cat /opt/victronenergy/version 2>/dev/null || echo 'unknown'")
echo_info "VenusOS version: ${VENUS_VERSION}"

# Check if GUI v2 directory exists
echo_info "Checking GUI v2 installation..."
if ! ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "[ -d ${REMOTE_GUI_PATH} ]"; then
    echo_error "GUI v2 directory not found at ${REMOTE_GUI_PATH}"
    echo_error "Make sure GUI v2 is enabled on your device."
    exit 1
fi

# Backup existing files
if [ "${DO_BACKUP}" = "1" ]; then
    echo_info "Backing up existing WASM files..."
    BACKUP_DIR="${REMOTE_GUI_PATH}/backup-$(date +%Y%m%d-%H%M%S)"
    ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "mkdir -p ${BACKUP_DIR} && cp ${REMOTE_GUI_PATH}/venus-gui-v2.* ${BACKUP_DIR}/ 2>/dev/null || true"
    echo_info "Backup created at ${BACKUP_DIR}"
fi

# Make filesystem writable
echo_info "Preparing filesystem..."
ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "mount -o remount,rw / 2>/dev/null || true"

# Deploy WASM files
echo_info "Deploying WASM files..."
scp ${SSH_OPTS} "${OUTPUT_DIR}/venus-gui-v2.wasm.gz" "${REMOTE_USER}@${CERBO_IP}:${REMOTE_GUI_PATH}/"
scp ${SSH_OPTS} "${OUTPUT_DIR}/venus-gui-v2.js" "${REMOTE_USER}@${CERBO_IP}:${REMOTE_GUI_PATH}/"
scp ${SSH_OPTS} "${OUTPUT_DIR}/venus-gui-v2.wasm.gz.sha256" "${REMOTE_USER}@${CERBO_IP}:${REMOTE_GUI_PATH}/"

# Copy qtloader.js if it exists
if [ -f "${OUTPUT_DIR}/qtloader.js" ]; then
    scp ${SSH_OPTS} "${OUTPUT_DIR}/qtloader.js" "${REMOTE_USER}@${CERBO_IP}:${REMOTE_GUI_PATH}/"
fi

# Set permissions
echo_info "Setting permissions..."
ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "chmod 644 ${REMOTE_GUI_PATH}/venus-gui-v2.*"

# Verify deployment
echo_info "Verifying deployment..."
REMOTE_SHA=$(ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "sha256sum ${REMOTE_GUI_PATH}/venus-gui-v2.wasm.gz | cut -d' ' -f1")
LOCAL_SHA=$(cat "${OUTPUT_DIR}/venus-gui-v2.wasm.gz.sha256" | cut -d' ' -f1)

if [ "${REMOTE_SHA}" = "${LOCAL_SHA}" ]; then
    echo_info "Checksum verified: OK"
else
    echo_warn "Checksum mismatch! Remote: ${REMOTE_SHA}, Local: ${LOCAL_SHA}"
fi

# Restart GUI if requested
if [ "${DO_RESTART}" = "1" ]; then
    echo_info "Restarting GUI service..."
    ssh ${SSH_OPTS} ${REMOTE_USER}@${CERBO_IP} "svc -t /service/gui 2>/dev/null || svc -t /service/start-gui 2>/dev/null || true"
    echo_info "GUI restart requested. It may take a few seconds."
fi

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "The custom GUI v2 WASM has been deployed to ${CERBO_IP}"
echo ""
echo "To see the changes:"
echo "  1. Clear your browser cache"
echo "  2. Refresh the Remote Console page"
echo "  3. Wait up to 10 minutes for VRM to sync (if using VRM)"
echo ""
echo "The Starlink settings page will appear at:"
echo "  Settings -> Starlink"
echo ""
echo "Note: The Starlink D-Bus service must be running for"
echo "      the Starlink menu to be visible."
echo ""
