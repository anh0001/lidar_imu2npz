# Use official ROS Noetic base image
FROM osrf/ros:noetic-desktop-full

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    mesa-utils \
    software-properties-common \
    wget \
    lsb-release \
    gnupg2 \
    curl \
    xauth \
    git \
    cmake \
    build-essential \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Gazebo
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list' \
    && wget https://packages.osrfoundation.org/gazebo.key -O - | apt-key add - \
    && apt-get update \
    && apt-get install -y \
    gazebo11 \
    ros-noetic-gazebo-ros \
    && rm -rf /var/lib/apt/lists/*

# Install NVIDIA Container Toolkit
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

RUN apt-get update && apt-get install -y \
    nvidia-docker2 \
    && rm -rf /var/lib/apt/lists/*

# Install specific versions of Python packages
RUN pip3 install --no-cache-dir \
    numpy==1.21.0 \
    tqdm \
    open3d \
    pandas

# Clone and build Livox-SDK2
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git \
    && cd Livox-SDK2 \
    && mkdir build \
    && cd build \
    && cmake .. && make -j \
    && make install \
    && cd ../.. \
    && rm -rf Livox-SDK2

# Configure entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Set default command
CMD ["bash"]

# Set the working directory
WORKDIR /workspace
