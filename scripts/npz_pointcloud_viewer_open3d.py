import numpy as np
import open3d as o3d
import argparse
import os
from tqdm import tqdm

def load_pointcloud(path):
    """Load point cloud data from npz file or directory."""
    if os.path.isdir(path):
        pointclouds = {}
        for file in os.listdir(path):
            if file.endswith('.npz'):
                file_path = os.path.join(path, file)
                data = np.load(file_path)
                if 'points' in data:
                    pointclouds[file] = data['points']
                else:
                    pointclouds[file] = data[list(data.keys())[0]]
        return pointclouds
    elif os.path.isfile(path):
        data = np.load(path)
        if 'points' in data:
            return {'single_cloud': data['points']}
        else:
            return {'single_cloud': data[list(data.keys())[0]]}
    else:
        raise ValueError(f"Invalid path: {path}")

def chunk_pointcloud(points, chunk_size=1000000):
    """Split the point cloud into manageable chunks."""
    for i in range(0, len(points), chunk_size):
        yield points[i:i + chunk_size]

def downsample_pointcloud(points, target_size=500000):
    """Downsample the point cloud to a target size using random sampling."""
    original_size = len(points)
    if original_size <= target_size:
        return points, original_size, original_size
    indices = np.random.choice(original_size, target_size, replace=False)
    return points[indices], original_size, target_size

def visualize_pointclouds_open3d(pointclouds):
    """Visualize point clouds using Open3D."""
    vis = o3d.visualization.Visualizer()
    vis.create_window()

    colors = [
        [1, 0, 0],  # Red
        [0, 1, 0],  # Green
        [0, 0, 1],  # Blue
        [1, 1, 0],  # Yellow
        [1, 0, 1],  # Magenta
        [0, 1, 1],  # Cyan
    ]

    print("Processing and adding point clouds to the viewer...")
    total_original = 0
    total_downsampled = 0
    for i, (name, points) in enumerate(pointclouds.items()):
        color = colors[i % len(colors)]
        for chunk in tqdm(list(chunk_pointcloud(points)), desc=f"Processing {name}"):
            chunk, original_size, downsampled_size = downsample_pointcloud(chunk)
            total_original += original_size
            total_downsampled += downsampled_size
            
            pcd = o3d.geometry.PointCloud()
            pcd.points = o3d.utility.Vector3dVector(chunk)
            pcd.paint_uniform_color(color)
            vis.add_geometry(pcd)

    print(f"Original total points: {total_original}")
    print(f"Downsampled total points: {total_downsampled}")
    print(f"Downsampling ratio: {total_downsampled/total_original:.2%}")

    # Set up the viewer
    opt = vis.get_render_option()
    opt.background_color = np.asarray([0.1, 0.1, 0.1])
    opt.point_size = 1.0

    # Set up the camera
    ctr = vis.get_view_control()
    ctr.set_zoom(0.8)
    ctr.set_front([0, 0, -1])
    ctr.set_lookat([0, 0, 0])
    ctr.set_up([0, -1, 0])

    print("Visualization window is now open. Close the window to exit.")
    vis.run()
    vis.destroy_window()

def main():
    parser = argparse.ArgumentParser(description='Visualize PointCloud data from NPZ file or directory using Open3D.')
    parser.add_argument('path', type=str, help='Path to the NPZ file or directory containing NPZ files')
    args = parser.parse_args()

    try:
        pointclouds = load_pointcloud(args.path)
        print(f"Loaded {len(pointclouds)} point cloud(s).")
        for name, points in pointclouds.items():
            print(f"  {name}: {len(points)} points")
    except Exception as e:
        print(f"Error loading file or directory: {str(e)}")
        return

    visualize_pointclouds_open3d(pointclouds)

if __name__ == "__main__":
    main()