#!/bin/bash
#
# Build Venus OS GUI v2 WASM with Starlink plugin
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

# Paths
BUILD_DIR="/build"
GUI_V2_DIR="${BUILD_DIR}/gui-v2"
OUTPUT_DIR="${BUILD_DIR}/output"
PATCHES_DIR="${BUILD_DIR}/patches"

# Qt paths
QT_VERSION="${QT_VERSION:-6.8.3}"
QT_PATH="${QT_PATH:-/opt/qt}"
QT_HOST_PATH="${QT_HOST_PATH:-${QT_PATH}/${QT_VERSION}/gcc_64}"
QT_WASM_PATH="${QT_WASM_PATH:-${QT_PATH}/${QT_VERSION}/wasm_singlethread}"
EMSDK_PATH="${EMSDK_PATH:-/opt/emsdk}"

echo ""
echo "=========================================="
echo "  Venus OS GUI v2 WASM Builder"
echo "=========================================="
echo ""

# Source Emscripten environment
echo_info "Setting up Emscripten environment..."
source "${EMSDK_PATH}/emsdk_env.sh"

# Update gui-v2 source if needed
if [ "${UPDATE_SOURCE:-0}" = "1" ]; then
    echo_info "Updating gui-v2 source..."
    cd "${GUI_V2_DIR}"
    git pull origin main || true
fi

# Apply Starlink patches
echo_info "Applying Starlink plugin patches..."
if [ -d "${PATCHES_DIR}" ] && [ "$(ls -A ${PATCHES_DIR}/*.patch 2>/dev/null)" ]; then
    cd "${GUI_V2_DIR}"
    for patch in "${PATCHES_DIR}"/*.patch; do
        if [ -f "$patch" ]; then
            echo_info "Applying patch: $(basename $patch)"
            git apply --check "$patch" 2>/dev/null && git apply "$patch" || {
                echo_warn "Patch already applied or failed: $(basename $patch)"
            }
        fi
    done
fi

# Copy Starlink QML files
echo_info "Installing Starlink QML pages..."
if [ -d "${PATCHES_DIR}/qml" ]; then
    cp -rv "${PATCHES_DIR}/qml/"* "${GUI_V2_DIR}/" 2>/dev/null || true
fi

# Create build directory
echo_info "Creating build directory..."
mkdir -p "${GUI_V2_DIR}/build-wasm"
cd "${GUI_V2_DIR}/build-wasm"

# Configure with CMake
echo_info "Configuring build with CMake..."
"${QT_WASM_PATH}/bin/qt-cmake" .. \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DQT_HOST_PATH="${QT_HOST_PATH}" \
    -G Ninja

# Build
echo_info "Building WASM (this may take a while)..."
ninja

# Create output directory
echo_info "Preparing output artifacts..."
mkdir -p "${OUTPUT_DIR}"

# Copy WASM artifacts
cp -v venus-gui-v2.wasm "${OUTPUT_DIR}/"
cp -v venus-gui-v2.js "${OUTPUT_DIR}/"
cp -v qtloader.js "${OUTPUT_DIR}/" 2>/dev/null || true

# Create gzipped version
echo_info "Compressing WASM binary..."
gzip -9 -k -f "${OUTPUT_DIR}/venus-gui-v2.wasm"

# Generate checksums
echo_info "Generating checksums..."
cd "${OUTPUT_DIR}"
sha256sum venus-gui-v2.wasm > venus-gui-v2.wasm.sha256
sha256sum venus-gui-v2.wasm.gz > venus-gui-v2.wasm.gz.sha256

# Create index.html for standalone testing
cat > "${OUTPUT_DIR}/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Venus OS GUI v2</title>
    <style>
        html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
        #qtspinner { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
        #qtspinner text { font-family: sans-serif; font-size: 14px; }
        canvas { width: 100%; height: 100%; }
    </style>
</head>
<body>
    <div id="qtspinner">
        <svg width="100" height="100" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="40" stroke="#ddd" stroke-width="8" fill="none"/>
            <circle cx="50" cy="50" r="40" stroke="#3498db" stroke-width="8" fill="none"
                    stroke-dasharray="251.2" stroke-dashoffset="0">
                <animate attributeName="stroke-dashoffset" values="0;251.2" dur="2s" repeatCount="indefinite"/>
            </circle>
            <text x="50" y="55" text-anchor="middle">Loading...</text>
        </svg>
    </div>
    <canvas id="qtcanvas"></canvas>
    <script src="qtloader.js"></script>
    <script src="venus-gui-v2.js"></script>
</body>
</html>
HTMLEOF

# List output files
echo ""
echo_info "Build complete! Output files:"
ls -lh "${OUTPUT_DIR}/"

echo ""
echo "=========================================="
echo "  Build Successful!"
echo "=========================================="
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "To deploy to your Cerbo, run:"
echo "  ./deploy.sh <cerbo-ip>"
echo ""
