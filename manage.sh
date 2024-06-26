#!/bin/bash

CONTAINER_NAME="ros-noetic-gazebo-gpu"
HOST_DIR="$(pwd)"
CONTAINER_DIR="/workspace"
SCRIPT_DIR=$(dirname "$0")
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/run_command_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to check and create directories if they don't exist
check_and_create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Function to check read/write permissions
check_permissions() {
    local dir="$1"
    local permission="$2"
    if [ ! "$permission" "$dir" ]; then
        log_message "Error: Cannot $permission from/to $dir. Please check permissions."
        exit 1
    fi
}

# Function to process each rosbag file
process_rosbag() {
    local src_bag="$1"
    local base_filename=$(basename "$src_bag")
    local dst_bag="$rosbag_processed_dir/fastlio_$base_filename"
    local log_file="$LOG_DIR/roslaunch_$(basename "$src_bag" .bag).log"

    log_message "Processing: $src_bag -> $dst_bag"
    
    if ! roslaunch fast_lio bag_mapping_mid360.launch src_bag:="$src_bag" dst_bag:="$dst_bag" &> "$log_file"; then
        log_message "Error processing $src_bag. Check the log file for details: $log_file"
    else
        log_message "Successfully processed $src_bag. Output written to $dst_bag"
    fi
}

# Main run_command function
run_command() {
    local rosbag_raw_dir="$(realpath "$SCRIPT_DIR/rosbag/raw")"
    local rosbag_processed_dir="$(realpath "$SCRIPT_DIR/rosbag/processed")"

    log_message "Raw rosbag directory: $rosbag_raw_dir"
    log_message "Processed rosbag directory: $rosbag_processed_dir"

    check_and_create_directory "$rosbag_processed_dir"
    check_permissions "$rosbag_raw_dir" -r
    check_permissions "$rosbag_processed_dir" -w

    for src_bag in "$rosbag_raw_dir"/*.bag; do
        if [ -f "$src_bag" ]; then
            process_rosbag "$src_bag"
        else
            log_message "No .bag files found in $rosbag_raw_dir."
        fi
    done
}

build_package() {
    # Check if ROS is installed by looking for the setup.bash file in common locations
    if [ -f "/opt/ros/noetic/setup.bash" ]; then
        ros_distribution="noetic"
    elif [ -f "/opt/ros/melodic/setup.bash" ]; then
        ros_distribution="melodic"
    else
        echo "Error: No supported ROS distribution found."
        return 1
    fi

    echo "Building ROS packages for $ros_distribution..."

    # Set ROS_EDITION variable
    export ROS_EDITION="ROS1"

    # Check if the ROS setup script exists
    local ros_setup_script="/opt/ros/$ros_distribution/setup.bash"
    if [[ ! -f "$ros_setup_script" ]]; then
        echo "Error: ROS setup script for $ros_distribution does not exist."
        return 1
    fi

    # Source the ROS setup.bash
    source "$ros_setup_script"

    # Change to the submodule directory and run its build.sh script with ROS1 argument
    pushd src/livox_ros_driver2 >/dev/null
    if ! ./build.sh ROS1; then
        echo "Error: Failed to build livox_ros_driver2."
        popd >/dev/null
        return 1
    fi
    popd >/dev/null

    # Check if a ROS package name is provided as an argument
    if [ "$#" -eq 1 ]; then
        # Build the specified ROS package
        if ! catkin_make --only-pkg-with-deps "$1"; then
            echo "Error: Failed to build the specified ROS package."
            return 1
        fi
    else
        # Build the entire workspace
        if ! catkin_make; then
            echo "Error: Failed to build the workspace."
            return 1
        fi
    fi

    echo "Build completed successfully."
}

build_container() {
    echo "Building Docker image..."
    docker build -t ros-noetic-gazebo-gpu .
}

start_container() {
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
            # Cleanup exited container
            docker rm $CONTAINER_NAME
        else
            echo "Container with name $CONTAINER_NAME is already running."
            return
        fi
    fi

    xhost +local:docker
    docker run --gpus all -it \
        --name $CONTAINER_NAME \
        --env="DISPLAY" \
        --env="QT_X11_NO_MITSHM=1" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --volume="$HOST_DIR:$CONTAINER_DIR" \
        ros-noetic-gazebo-gpu
}

enter_container() {
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        docker exec -it $CONTAINER_NAME bash
    else
        echo "No running container with name $CONTAINER_NAME found."
    fi
}

if [ "$1" == "build-container" ]; then
    build_container
elif [ "$1" == "start" ]; then
    start_container
elif [ "$1" == "enter" ]; then
    enter_container
elif [ "$1" == "build" ]; then
    build_package
elif [ "$1" == "run" ]; then
    run_command
else
    echo "Usage: $0 [build-container|start|enter|build|run]"
fi
