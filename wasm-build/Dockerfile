#
# Venus OS GUI v2 WASM Build Environment
#
# This Dockerfile creates a build environment for compiling
# custom GUI v2 WASM binaries with the Starlink plugin.
#
# Based on: https://github.com/victronenergy/gui-v2/wiki/How-to-build-venus-gui-v2
#
# Uses official Emscripten Docker image to avoid tar extraction issues
#

# Use official Emscripten SDK image as base
# Qt 6.5.3 was built with emsdk 3.1.37
FROM emscripten/emsdk:3.1.37

LABEL maintainer="Starlink Control Plugin"
LABEL description="Build environment for Venus OS GUI v2 WASM"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Qt version - must match emsdk version compatibility
# Qt 6.5.3 LTS has stable WASM support via aqt and works with emsdk 3.1.37
ENV QT_VERSION=6.5.3
ENV QT_PATH=/opt/qt

# Install additional dependencies for Qt
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    curl \
    p7zip-full \
    xz-utils \
    libgl1-mesa-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrender-dev \
    libxcb1-dev \
    libxcb-glx0-dev \
    libxcb-util0-dev \
    openssh-client \
    rsync \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment for aqt
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install aqtinstall for Qt installation
RUN pip install --no-cache-dir aqtinstall

# Debug: List available architectures for our Qt version
RUN echo "=== Available architectures for Qt ${QT_VERSION} ===" && \
    aqt list-qt linux desktop --arch ${QT_VERSION} || true

# Install Qt for desktop (needed for host tools)
RUN aqt install-qt linux desktop ${QT_VERSION} gcc_64 \
    --outputdir ${QT_PATH}

# Install Qt for WebAssembly (single-threaded)
# For Qt 6.5.x the architecture is 'wasm_singlethread'
RUN aqt install-qt linux desktop ${QT_VERSION} wasm_singlethread \
    --outputdir ${QT_PATH}

# Set Qt environment variables
ENV QT_HOST_PATH=${QT_PATH}/${QT_VERSION}/gcc_64
ENV QT_WASM_PATH=${QT_PATH}/${QT_VERSION}/wasm_singlethread
ENV PATH="${QT_HOST_PATH}/bin:${PATH}"

# Emscripten is already set up from base image at /emsdk
# Just ensure environment is properly configured
ENV EMSDK=/emsdk
ENV EM_CONFIG=/emsdk/.emscripten

# Create working directory
WORKDIR /build

# Clone gui-v2 repository
RUN git clone --depth 1 https://github.com/victronenergy/gui-v2.git /build/gui-v2

# Build QtMqtt module for WASM (required dependency)
RUN cd /build && \
    git clone --depth 1 --branch v${QT_VERSION} https://github.com/qt/qtmqtt.git && \
    cd qtmqtt && \
    mkdir build-wasm && cd build-wasm && \
    . ${EMSDK}/emsdk_env.sh && \
    ${QT_WASM_PATH}/bin/qt-cmake .. \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DQT_HOST_PATH=${QT_HOST_PATH} \
        -G Ninja && \
    ninja && \
    ninja install

# Copy build and deploy scripts
COPY scripts/ /build/scripts/
RUN chmod +x /build/scripts/*.sh

# Copy patches directory (for Starlink integration)
COPY patches/ /build/patches/

# Default command
CMD ["/build/scripts/build-wasm.sh"]
