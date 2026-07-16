# Docker build environment for Cartographer (ROS 2 Humble, Ubuntu 22.04)
#
# All dependencies are installed, cartographer + cartographer_ros source
# are cloned and built inside the image.
#
# Build the image:
#   docker build -t cartographer-ros2:V1.0 .
#
# Run interactively:
#   ./docker/run.sh

FROM ubuntu:22.04

# Use bash for all RUN commands — ROS 2 setup.bash requires bash-specific syntax
SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------
# 1. System packages + build toolchain
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # gosu for clean user-switching in entrypoint
    gosu \
    # Build toolchain
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Git & networking
    git \
    wget \
    curl \
    ca-certificates \
    gnupg2 \
    lsb-release \
    # Python
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    # System libraries
    libssl-dev \
    libsqlite3-dev \
    libncurses-dev \
    libusb-1.0-0-dev \
    # Utilities
    sudo \
    vim \
    unzip \
    rsync \
    locales \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 2. Locale
# ------------------------------------------------------------
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# ------------------------------------------------------------
# 3. ROS 2 Humble installation
# ------------------------------------------------------------
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-humble-pcl-ros \
    ros-humble-tf2 \
    ros-humble-tf2-ros \
    ros-humble-tf2-eigen \
    ros-humble-tf2-sensor-msgs \
    ros-humble-sensor-msgs \
    ros-humble-nav-msgs \
    ros-humble-geometry-msgs \
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-ament-cmake-auto \
    ros-humble-ament-lint-auto \
    ros-humble-rclcpp-components \
    python3-rosdep \
    python3-rosinstall-generator \
    python3-vcstool \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 4. Cartographer dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Ceres Solver (non-linear optimization, scan matching core)
    libceres-dev \
    # Eigen3 (linear algebra)
    libeigen3-dev \
    # PCL (Point Cloud Library)
    libpcl-dev \
    # Abseil (Google C++ base library)
    libabsl-dev \
    # Protobuf (serialization)
    libprotobuf-dev \
    protobuf-compiler \
    # Lua 5.2 (parameter/config parsing)
    liblua5.2-dev \
    # gflags + glog (CLI args + logging)
    libgflags-dev \
    libgoogle-glog-dev \
    # Cairo (submap visualization)
    libcairo2-dev \
    # Boost (asio, iostreams, etc.)
    libboost-all-dev \
    # OpenCV (optional, for image processing)
    libopencv-dev \
    # YAML config
    libyaml-cpp-dev \
    # pkg-config for find_package
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 5. Build abseil-cpp from source (fallback)
#    Cartographer needs absl::flat_hash_map etc.
#    Ubuntu 22.04 libabsl-dev (20210324.2) is sufficient,
#    but building from source guarantees ABI compatibility.
#    Uncomment below if you encounter ABI issues with libabsl-dev.
# ------------------------------------------------------------
# RUN git clone --depth 1 -b 20220623.1 https://github.com/abseil/abseil-cpp.git /tmp/abseil && \
#     mkdir -p /tmp/abseil/build && cd /tmp/abseil/build && \
#     cmake .. \
#         -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         -DABSL_BUILD_TESTING=OFF \
#         -DABSL_USE_GOOGLETEST_HEAD=OFF \
#         -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
#     && make -j$(nproc) install && \
#     rm -rf /tmp/abseil

# ------------------------------------------------------------
# 6. Copy and build cartographer (core library)
# ------------------------------------------------------------
COPY src/cartographer /tmp/cartographer
RUN mkdir -p /tmp/cartographer/build && cd /tmp/cartographer/build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_GRPC=OFF \
    && make -j$(nproc) install && \
    rm -rf /tmp/cartographer

# ------------------------------------------------------------
# 7. Build cartographer_ros (ROS 2 workspace)
# ------------------------------------------------------------
RUN mkdir -p /opt/cartographer_ws/src
COPY src/cartographer_ros /opt/cartographer_ws/src/cartographer_ros
RUN cd /opt/cartographer_ws && \
    . /opt/ros/humble/setup.bash && \
    colcon build \
        --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && rm -rf /opt/cartographer_ws/build /opt/cartographer_ws/log

# ------------------------------------------------------------
# 8. ROS environment setup script
# ------------------------------------------------------------
RUN echo '#!/bin/bash' > /usr/local/bin/ros2_setup.sh && \
    echo 'source /opt/ros/humble/setup.bash' >> /usr/local/bin/ros2_setup.sh && \
    echo 'source /opt/cartographer_ws/install/setup.bash' >> /usr/local/bin/ros2_setup.sh && \
    echo '# Source host workspace overlay if mounted' >> /usr/local/bin/ros2_setup.sh && \
    echo 'if [ -f /workspace/install/setup.bash ]; then' >> /usr/local/bin/ros2_setup.sh && \
    echo '    source /workspace/install/setup.bash' >> /usr/local/bin/ros2_setup.sh && \
    echo 'fi' >> /usr/local/bin/ros2_setup.sh && \
    chmod +x /usr/local/bin/ros2_setup.sh

# Add to bashrc so every shell sources ROS 2 automatically
RUN echo 'source /usr/local/bin/ros2_setup.sh' >> /etc/bash.bashrc

# ------------------------------------------------------------
# 9. Entrypoint wrapper
# ------------------------------------------------------------
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
