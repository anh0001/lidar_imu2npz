# NPZ PointCloud Viewer

This Python script visualizes point cloud data stored in NPZ (NumPy Compressed) files using Open3D. It supports visualizing single NPZ files or multiple NPZ files from a directory.

## Features

- Load point cloud data from single NPZ file or directory containing multiple NPZ files
- Visualize point clouds using Open3D
- Automatic downsampling for large point clouds
- Chunked processing for memory efficiency
- Color-coded visualization for multiple point clouds
- Progress bar for processing large datasets

## Requirements

- Python 3.x
- numpy
- open3d
- tqdm

You can install the required packages using pip:
```bash
pip install numpy open3d tqdm
```

## Usage
```bash
python npz_pointcloud_viewer_open3d.py <path>
```

### Arguments:

- `path`: Path to the NPZ file or directory containing NPZ files

### Examples:

1. Visualize a single NPZ file:
```bash
python npz_pointcloud_viewer_open3d.py path/to/your/pointcloud.npz
```
2. Visualize multiple NPZ files in a directory:
```bash
python npz_pointcloud_viewer_open3d.py path/to/your/npz_folder/
```

## Functionality

1. **Loading Data**: The script can load point cloud data from a single NPZ file or multiple NPZ files in a directory.

2. **Downsampling**: Large point clouds are automatically downsampled to a target size (default: 500,000 points) to improve visualization performance.

3. **Chunked Processing**: Point clouds are processed in chunks to manage memory usage efficiently.

4. **Visualization**: 
- Single point cloud: Displayed in a uniform color.
- Multiple point clouds: Each point cloud is displayed in a different color for easy distinction.

5. **Viewer Controls**: 
- Use the mouse to rotate, pan, and zoom the view.
- Close the viewer window to exit the program.

## Output

The script will open a visualization window showing the point cloud(s). It also prints information about the loaded data and downsampling statistics to the console.

## Note

For very large datasets, the initial loading and processing may take some time. The progress is displayed in the console to keep you informed of the current status.