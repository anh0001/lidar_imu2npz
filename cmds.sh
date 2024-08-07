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
    
    if ! roslaunch launch/bag_mapping_mid360.launch src_bag:="$src_bag" dst_bag:="$dst_bag" &> "$log_file"; then
        log_message "Error processing $src_bag. Check the log file for details: $log_file"
    else
        log_message "Successfully processed $src_bag. Output written to $dst_bag"
    fi
}

# Function to convert processed rosbag files to npz
process_npz() {
    local src_bag="$1"
    local base_filename=$(basename "$src_bag" .bag)
    local output_dir="$SCRIPT_DIR/out"
    local log_file="$LOG_DIR/npz_$(basename "$src_bag" .bag).log"

    check_and_create_directory "$output_dir"
    
    log_message "Converting: $src_bag to npz format"
    
    if ! python3 scripts/pointcloud2_to_npz.py "$src_bag" -t /cloud_registered -o "$output_dir" &> "$log_file"; then
        log_message "Error converting $src_bag to npz. Check the log file for details: $log_file"
    else
        log_message "Successfully converted $src_bag to npz format. Output written to $output_dir"
    fi
}

# Function to visualize the npz point cloud
visualize_pointcloud() {
    local npz_file="$1"
    if [ ! -f "$npz_file" ]; then
        log_message "Error: Specified file $npz_file does not exist."
        exit 1
    fi

    log_message "Visualizing: $npz_file"

    if ! python3 scripts/npz_pointcloud_viewer_open3d.py "$npz_file"; then
        log_message "Error visualizing $npz_file. Please check the file and try again."
    else
        log_message "Successfully visualized $npz_file."
    fi
}

# Function to visualize all npz point clouds
visualize_all() {
    local npz_dir="$SCRIPT_DIR/out"
    log_message "Visualizing all npz files in $npz_dir"

    for npz_file in "$npz_dir"/*.npz; do
        if [ -f "$npz_file" ]; then
            visualize_pointcloud "$npz_file"
        else
            log_message "No npz files found in $npz_dir."
        fi
    done
}

# Function to combine maps into an npz file
combine_maps_to_npz() {
    local rosbag_processed_dir="$(realpath "$SCRIPT_DIR/rosbag/processed")"
    local output_dir="$SCRIPT_DIR/out"
    check_and_create_directory "$output_dir"

    log_message "Combining maps into npz files from $rosbag_processed_dir"

    for processed_bag in "$rosbag_processed_dir"/*.bag; do
        if [ -f "$processed_bag" ]; then
            local base_filename=$(basename "$processed_bag" .bag)
            local combined_npz="$output_dir/combined.npz"
            log_message "Combining: $processed_bag to $combined_npz"

            if ! python3 scripts/pointcloud2_to_npz.py "$processed_bag" -t /cloud_registered -o "$combined_npz" -s &> "$LOG_DIR/combine_npz_$base_filename.log"; then
                log_message "Error combining $processed_bag into npz. Check the log file for details: $LOG_DIR/combine_npz_$base_filename.log"
            else
                log_message "Successfully combined $processed_bag into npz format. Output written to $combined_npz"
            fi
        else
            log_message "No processed .bag files found in $rosbag_processed_dir."
        fi
    done
}

# Main run_command function
run_fastlio() {
    local rosbag_raw_dir="$(realpath "$SCRIPT_DIR/rosbag/raw")"
    local rosbag_processed_dir="$(realpath "$SCRIPT_DIR/rosbag/processed")"

    log_message "Raw rosbag directory: $rosbag_raw_dir"
    log_message "Processed rosbag directory: $rosbag_processed_dir"

    check_and_create_directory "$rosbag_processed_dir"
    check_permissions "$rosbag_raw_dir" -r
    check_permissions "$rosbag_processed_dir" -w

    for src_bag in "$rosbag_raw_dir"/*.bag; do
        if [ -f "$src_bag" ];then
            process_rosbag "$src_bag"
        else
            log_message "No .bag files found in $rosbag_raw_dir."
        fi
    done
}

run_convert_npz() {
    local rosbag_processed_dir="$(realpath "$SCRIPT_DIR/rosbag/processed")"

    log_message "Processed rosbag directory: $rosbag_processed_dir"

    check_permissions "$rosbag_processed_dir" -r

    for processed_bag in "$rosbag_processed_dir"/*.bag; do
        if [ -f "$processed_bag" ];then
            process_npz "$processed_bag"
        else
            log_message "No processed .bag files found in $rosbag_processed_dir."
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
        docker exec -it $CONTAINER_NAME bash -c "source /opt/ros/noetic/setup.bash && exec bash"
    else
        echo "No running container with name $CONTAINER_NAME found."
    fi
}

# Function to clear logs in the logs folder
clear_logs() {
    log_message "Clearing all logs in $LOG_DIR"
    rm -rf "$LOG_DIR"/*
    log_message "Logs cleared."
}

# Main entry point
case "$1" in
    build-container) build_container ;;
    start) start_container ;;
    enter) enter_container ;;
    build) build_package ;;
    run-fastlio-mapping) run_fastlio ;;
    map-to-npz) run_convert_npz ;;
    combine-maps-to-npz) combine_maps_to_npz ;;
    visualize-pc)
        if [ -z "$2" ]; then
            echo "Error: Please specify the npz file to visualize."
            echo "Usage: $0 visualize-pc <file.npz>"
            exit 1
        fi
        visualize_pointcloud "$2"
        ;;
    visualize-all) visualize_all ;;
    clear-logs) clear_logs ;;
    *)
        echo "Usage: $0 [build-container|start|enter|build|run-fastlio-mapping|map-to-npz|combine-maps-to-npz|visualize-pc|visualize-all|clear-logs]"
        ;;
esac

# Enable tab completion
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    _commands_completions() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local commands="build-container start enter build run-fastlio-mapping map-to-npz combine-maps-to-npz visualize-pc visualize-all clear-logs"
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    }
    complete -F _commands_completions cmds.sh
fi
