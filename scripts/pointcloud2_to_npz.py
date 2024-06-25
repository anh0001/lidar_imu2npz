import rosbag
import sensor_msgs.point_cloud2 as pc2
import numpy as np
import argparse
import sys
import os
from datetime import datetime
from tqdm import tqdm

def get_topics(bag_file):
    topics = set()
    with rosbag.Bag(bag_file, 'r') as bag:
        for topic, _, _ in bag.read_messages():
            topics.add(topic)
    return sorted(topics)

def is_pointcloud2_message(msg):
    return hasattr(msg, 'height') and hasattr(msg, 'width') and hasattr(msg, 'fields') and hasattr(msg, 'point_step')

def count_messages(bag_file, topic):
    count = 0
    with rosbag.Bag(bag_file, 'r') as bag:
        for _, msg, _ in bag.read_messages(topics=[topic]):
            if is_pointcloud2_message(msg):
                count += 1
    return count

def read_pointcloud2_messages(bag_file, topic):
    with rosbag.Bag(bag_file, 'r') as bag:
        for _, msg, t in bag.read_messages(topics=[topic]):
            if is_pointcloud2_message(msg):
                yield msg, t

def process_pointcloud2(msg):
    xyz_list = []
    for point in pc2.read_points(msg, field_names=("x", "y", "z"), skip_nans=True):
        xyz_list.append(point)
    return np.array(xyz_list, dtype=np.float32)

def save_single_npz(output_path, points):
    np.savez_compressed(output_path, points=points)
    print(f"Saved all point clouds to {output_path}")
    print(f"Total number of points in the combined cloud: {len(points)}")

def save_multiple_npz(output_dir, pointclouds):
    for timestamp, points in pointclouds.items():
        output_filename = f"pointcloud_{timestamp}.npz"
        output_path = os.path.join(output_dir, output_filename)
        np.savez_compressed(output_path, points=points)
    print(f"Saved {len(pointclouds)} point cloud files to {output_dir}")

def main():
    parser = argparse.ArgumentParser(description='Convert PointCloud2 messages from a ROS bag file to NPZ files.')
    parser.add_argument('bag_file', type=str, help='Path to the ROS bag file')
    parser.add_argument('-t', '--topic', type=str, help='Topic name for PointCloud2 messages')
    parser.add_argument('-o', '--output', type=str, help='Output directory or file name for NPZ files')
    parser.add_argument('-l', '--list', action='store_true', help='List all topics in the bag file')
    parser.add_argument('-s', '--single', action='store_true', help='Save all point clouds in a single NPZ file')
    args = parser.parse_args()

    try:
        if args.list:
            topics = get_topics(args.bag_file)
            print("Topics in the bag file:")
            for topic in topics:
                print(f"  {topic}")
            return

        if not args.topic:
            print("Error: Please specify a topic using the -t or --topic option.")
            return

        # Set default output path if not provided
        if args.output is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            args.output = f"pointcloud_output_{timestamp}"

        # Create output directory if it doesn't exist and we're not using single file mode
        if not args.single:
            os.makedirs(args.output, exist_ok=True)

        # Count total number of messages
        total_messages = count_messages(args.bag_file, args.topic)
        if total_messages == 0:
            print(f"No PointCloud2 messages found on topic {args.topic}")
            return

        print(f"Found {total_messages} PointCloud2 messages. Starting conversion...")

        # Process messages with progress bar
        all_points = []
        total_points = 0
        with tqdm(total=total_messages, unit='message') as pbar:
            for msg, _ in read_pointcloud2_messages(args.bag_file, args.topic):
                points = process_pointcloud2(msg)
                all_points.append(points)
                total_points += len(points)
                pbar.update(1)
                pbar.set_postfix({'Total Points': total_points})

        # Combine all points into a single array
        combined_points = np.concatenate(all_points, axis=0)

        # Save the point clouds
        if args.single:
            if not args.output.endswith('.npz'):
                args.output += '.npz'
            save_single_npz(args.output, combined_points)
        else:
            save_multiple_npz(args.output, {datetime.now().strftime("%Y%m%d_%H%M%S"): combined_points})

        print(f"Total number of PointCloud2 messages processed: {total_messages}")
        print(f"Shape of the combined point cloud: {combined_points.shape}")

    except rosbag.ROSBagException as e:
        print(f"Error reading bag file: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()