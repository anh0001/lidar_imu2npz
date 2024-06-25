#!/bin/bash
set -e

# Source ROS setup.bash
source /opt/ros/noetic/setup.bash

exec "$@"
