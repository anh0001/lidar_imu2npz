
# 3D Point Clouds from Livox Mid-360 LiDAR on Mobile Robot

This project aims to build 3D point clouds from the 3D LiDAR Livox Mid-360 attached to a mobile robot. The sensor data, including LiDAR points, IMU, and TF, are recorded and processed by this project to perform SLAM (Simultaneous Localization and Mapping) and eventually create and visualize 3D point clouds.

## Features
- Build 3D point clouds using Livox Mid-360 LiDAR.
- Perform SLAM with recorded LiDAR and IMU data.
- Visualize the 3D point clouds.
- Utilize Docker for easy setup and deployment.
- Supports ROS Noetic, RViz, and Gazebo with GPU acceleration.
- Multiple rosbags of Livox sensor recording and output a single or multiple NPZ files.

## Prerequisites
- Docker
- NVIDIA Docker (for GPU support)

## Installation

1. **Clone the Repository**

   ```sh
   git clone https://github.com/anh0001/lidar_imu2npz.git
   cd lidar_imu2npz
   ```

2. **Initialize Submodules**

   As this repository contains submodules, you need to initialize and update them:

   ```sh
   git submodule update --init --recursive
   ```

3. **Build the Docker Container**

   Use the provided script to build the Docker container:

   ```sh
   ./cmds.sh build-container
   ```

4. **Start the Docker Container**

   Enter the Docker container with the following command:

   ```sh
   ./cmds.sh start
   ```

## Usage

1. **Enter the Docker Container**

   If the container is already running, use the following command to enter it:

   ```sh
   ./cmds.sh enter
   ```

2. **Source the Commands Script**

   Inside the container, source the commands script to load the necessary environment variables:

   ```sh
   source cmds.sh
   ```

3. **Prepare ROSBAG Data**

   Place all your ROSBAG data into the `rosbag/raw` folder.

4. **Run FastLIO Mapping**

   Execute the following command to process the ROSBAG data and output the results in the `rosbag/processed` folder:

   ```sh
   ./cmds.sh run-fastlio-mapping
   ```

5. **Combine Maps into a Single NPZ File**

   To combine all processed maps into a single `.npz` file, run:

   ```sh
   ./cmds.sh combine-maps-to-npz
   ```

   This will output `.npz` files in the `out` folder.

   If you want to convert each map individually, run:

   ```sh
   ./cmds.sh map-to-npz
   ```

## Visualization

Use RViz for visualizing the 3D point clouds. 

To visualize a single `.npz` file, use:

   ```sh
   ./cmds.sh visualize-pc
   ```

To visualize all `.npz` files in the `out/` folder, run:

   ```sh
   ./cmds.sh visualize-all
   ```

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/fooBar`).
3. Commit your changes (`git commit -am 'Add some fooBar'`).
4. Push to the branch (`git push origin feature/fooBar`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Livox](https://www.livoxtech.com/mid-360) for the Mid-360 LiDAR.
- [ROS](https://www.ros.org/) for providing the robotics framework.
- [Docker](https://www.docker.com/) for containerization technology.
