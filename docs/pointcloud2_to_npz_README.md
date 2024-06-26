# ROS PointCloud2 to NPZ Converter

This Python script converts PointCloud2 messages from a ROS bag file to NPZ (NumPy Compressed) files. It provides options for saving the point cloud data as multiple files or as a single combined file.

## Features

- List all topics in a ROS bag file
- Convert PointCloud2 messages to NPZ format
- Option to save as multiple NPZ files or a single combined file
- Progress bar to track conversion process
- Downsampling of large point clouds (optional)

## Requirements

- Python 3.x
- rosbag
- numpy
- tqdm

You can install the required packages using pip:
```bash
pip install rosbag numpy tqdm
```

## Usage
```bash
python pointcloud2_to_npz.py <bag_file> -t <topic> [options]
```

### Arguments:

- `bag_file`: Path to the ROS bag file
- `-t, --topic`: Topic name for PointCloud2 messages
- `-o, --output`: Output directory or file name for NPZ files (default: pointcloud_output_YYYYMMDD_HHMMSS)
- `-l, --list`: List all topics in the bag file
- `-s, --single`: Save all point clouds in a single NPZ file

### Examples:

1. List all topics in a bag file:
```bash
python pointcloud2_to_npz.py your_bagfile.bag -l
```
2. Convert PointCloud2 messages to multiple NPZ files:
```bash
python pointcloud2_to_npz.py your_bagfile.bag -t /pointcloud_topic -o output_directory
```
3. Convert PointCloud2 messages to a single NPZ file:
```bash
python pointcloud2_to_npz.py your_bagfile.bag -t /pointcloud_topic -o combined_output.npz -s
```

## Output

The script will create NPZ files containing the point cloud data. If the `-s` option is used, a single NPZ file will be created. Otherwise, multiple NPZ files will be created in the specified output directory.

Each NPZ file contains a 'points' array with shape (N, 3), where N is the number of points and the columns represent X, Y, and Z coordinates.

## Note

Large point clouds may require significant processing time and memory. Consider using the downsampling option if you encounter memory issues with very large datasets.