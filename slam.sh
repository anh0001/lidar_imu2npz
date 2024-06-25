#!/bin/bash

CONTAINER_NAME="ros-noetic-gazebo-gpu"
HOST_DIR="$(pwd)"
CONTAINER_DIR="/workspace"

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

if [ "$1" == "build" ]; then
    build_container
elif [ "$1" == "start" ]; then
    start_container
elif [ "$1" == "enter" ]; then
    enter_container
else
    echo "Usage: $0 {build|start|enter}"
fi
