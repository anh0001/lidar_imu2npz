#!/bin/bash

# Set ROS_EDITION variable
export ROS_EDITION="ROS1"

# Source the ROS setup.bash
source /opt/ros/noetic/setup.bash  # Change 'noetic' to your ROS1 distribution

# Change to the submodule directory and run its build.sh script with ROS1 argument
cd src/livox_ros_driver2
./build.sh ROS1

# Go back to the workspace root and build the entire workspace
cd ../../
catkin_make
