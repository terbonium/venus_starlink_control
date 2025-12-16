#
# Venus OS GUI v2 WASM Build Environment
#
# This Dockerfile creates a build environment for compiling
# custom GUI v2 WASM binaries with the Starlink plugin.
#
# Based on: https://github.com/victronenergy/gui-v2/wiki/How-to-build-venus-gui-v2
#

FROM ubuntu:24.04

LABEL maintainer="Starlink Control Plugin"
LABEL description="Build environment for Venus OS GUI v2 WASM"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Qt and Emscripten versions (match Venus OS requirements)
ENV QT_VERSION=6.8.3
ENV EMSDK_VERSION=3.1.56
ENV QT_PATH=/opt/qt
ENV EMSDK_PATH=/opt/emsdk

# Install base dependencies
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

# Install Qt for desktop (needed for some build tools)
RUN aqt install-qt linux desktop ${QT_VERSION} gcc_64 \
    --outputdir ${QT_PATH} \
    -m qtshadertools qtwebsockets

# Install Qt for WebAssembly (single-threaded)
RUN aqt install-qt linux desktop ${QT_VERSION} wasm_singlethread \
    --outputdir ${QT_PATH} \
    -m qtshadertools qtwebsockets

# Set Qt environment variables
ENV QT_HOST_PATH=${QT_PATH}/${QT_VERSION}/gcc_64
ENV QT_WASM_PATH=${QT_PATH}/${QT_VERSION}/wasm_singlethread
ENV PATH="${QT_HOST_PATH}/bin:${PATH}"

# Install Emscripten
RUN git clone https://github.com/emscripten-core/emsdk.git ${EMSDK_PATH} \
    && cd ${EMSDK_PATH} \
    && ./emsdk install ${EMSDK_VERSION} \
    && ./emsdk activate ${EMSDK_VERSION}

# Set Emscripten environment
ENV EMSDK=${EMSDK_PATH}
ENV EM_CONFIG=${EMSDK_PATH}/.emscripten
ENV PATH="${EMSDK_PATH}:${EMSDK_PATH}/upstream/emscripten:${PATH}"

# Create working directory
WORKDIR /build

# Clone gui-v2 repository
RUN git clone --depth 1 https://github.com/victronenergy/gui-v2.git /build/gui-v2

# Build QtMqtt module for WASM (required dependency)
RUN cd /build && \
    git clone --depth 1 --branch v${QT_VERSION} https://github.com/qt/qtmqtt.git && \
    cd qtmqtt && \
    mkdir build-wasm && cd build-wasm && \
    source ${EMSDK_PATH}/emsdk_env.sh && \
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
