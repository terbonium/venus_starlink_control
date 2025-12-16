#!/bin/bash
#
# Venus OS GUI v2 WASM Build Script
#
# This script builds the GUI v2 WASM with Starlink integration
# using Docker, then optionally deploys to a remote Cerbo.
#
# Usage:
#   ./build.sh                     # Build only
#   ./build.sh --deploy <ip>       # Build and deploy
#   ./build.sh --deploy-only <ip>  # Deploy existing build
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
IMAGE_NAME="venus-gui-v2-builder"
CONTAINER_NAME="venus-gui-v2-build"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Parse arguments
ACTION="build"
CERBO_IP=""
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --deploy)
            ACTION="build-deploy"
            CERBO_IP="$2"
            shift 2
            ;;
        --deploy-only)
            ACTION="deploy-only"
            CERBO_IP="$2"
            shift 2
            ;;
        --rebuild)
            ACTION="rebuild"
            shift
            ;;
        --shell)
            ACTION="shell"
            shift
            ;;
        --help|-h)
            echo "Venus OS GUI v2 WASM Builder with Starlink Integration"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --deploy <ip>       Build and deploy to Cerbo at <ip>"
            echo "  --deploy-only <ip>  Deploy existing build to Cerbo"
            echo "  --rebuild           Force rebuild Docker image"
            echo "  --shell             Open shell in build container"
            echo "  --help              Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                  # Build WASM only"
            echo "  $0 --deploy 192.168.1.100"
            echo "  $0 --deploy-only 192.168.1.100"
            echo ""
            exit 0
            ;;
        *)
            echo_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check Docker is available
if ! command -v docker &> /dev/null; then
    echo_error "Docker is not installed or not in PATH"
    exit 1
fi

# Build Docker image if needed
build_image() {
    echo_info "Building Docker image..."
    docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
}

# Check if image exists
check_image() {
    if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
        echo_info "Docker image not found, building..."
        build_image
    fi
}

# Run build in container
run_build() {
    echo_info "Starting WASM build in Docker container..."

    # Create output directory
    mkdir -p "${OUTPUT_DIR}"

    # Run build
    docker run --rm \
        -v "${OUTPUT_DIR}:/build/output" \
        -v "${SCRIPT_DIR}/patches:/build/patches:ro" \
        --name "${CONTAINER_NAME}" \
        "${IMAGE_NAME}" \
        /build/scripts/build-wasm.sh

    echo_info "Build artifacts available at: ${OUTPUT_DIR}"
}

# Deploy to Cerbo
run_deploy() {
    if [ -z "${CERBO_IP}" ]; then
        echo_error "No Cerbo IP specified"
        exit 1
    fi

    echo_info "Deploying to ${CERBO_IP}..."

    # Run deploy script locally (needs SSH access)
    OUTPUT_DIR="${OUTPUT_DIR}" "${SCRIPT_DIR}/scripts/deploy.sh" "${CERBO_IP}" --backup --restart
}

# Open shell in container
run_shell() {
    echo_info "Opening shell in build container..."
    docker run -it --rm \
        -v "${OUTPUT_DIR}:/build/output" \
        -v "${SCRIPT_DIR}/patches:/build/patches" \
        --name "${CONTAINER_NAME}-shell" \
        "${IMAGE_NAME}" \
        /bin/bash
}

# Main
echo ""
echo "=========================================="
echo "  Venus OS GUI v2 WASM Builder"
echo "  with Starlink Integration"
echo "=========================================="
echo ""

case "${ACTION}" in
    build)
        check_image
        run_build
        ;;
    rebuild)
        build_image
        run_build
        ;;
    build-deploy)
        check_image
        run_build
        run_deploy
        ;;
    deploy-only)
        run_deploy
        ;;
    shell)
        check_image
        run_shell
        ;;
esac

echo ""
echo_info "Done!"
