#!/usr/bin/env python

import os
import subprocess
import argparse
from collections import defaultdict

def find_similar_files(directory, threshold=70):
    """
    Use ssdeep to find files with more than a certain similarity threshold.

    :param directory: The directory to scan for similar files.
    :param threshold: The similarity threshold (default is 70%).
    """
    try:
        # Check if the directory exists
        if not os.path.isdir(directory):
            print(f"The directory '{directory}' does not exist")
            return

        # Recursively gather all file paths in the directory
        files_in_directory = []
        for root, _, files in os.walk(directory):
            for file in files:
                files_in_directory.append(os.path.join(root, file))

        # Check if there are files to process
        if not files_in_directory:
            print(f"No files found in '{directory}'")
            return

        # Build the ssdeep command with the gathered file paths
        ssdeep_command = ['ssdeep', '-d'] + files_in_directory

        # Run the ssdeep command using subprocess
        result = subprocess.run(ssdeep_command, capture_output=True, text=True)

        # Check if the command ran successfully
        if result.returncode == 0:
            if result.stdout:
                # Process the output to filter by threshold
                clusters = defaultdict(list)
                lines = result.stdout.splitlines()
                
                # Process each line (ssdeep -d output structure)
                for line in lines:
                    parts = line.rsplit(',', 2)  # Split from the right to capture similarity at the end
                    if len(parts) == 3:
                        try:
                            file1 = parts[0].strip()
                            file2 = parts[1].strip()
                            similarity = int(parts[2].strip('% '))  # Extract similarity percentage

                            # Check if similarity is within the valid range
                            if similarity >= threshold:
                                # Add absolute paths to clusters based on similarity
                                abs_file1 = os.path.abspath(file1)
                                abs_file2 = os.path.abspath(file2)
                                clusters[similarity].extend([abs_file1, abs_file2])
                        except ValueError:
                            # Skip if similarity is not a valid number
                            continue

                # Print clusters of filenames in a neat format
                if clusters:
                    similar_clusters = [files for files in clusters.items() if len(files[1]) > 1]
                    if similar_clusters:
                        for i, (similarity, cluster) in enumerate(similar_clusters, 1):
                            print(f"Cluster {i} ({similarity}% similarity):")
                            for file in set(cluster):
                                print(f"  {file}")
                            print()  # Add a new line after each cluster
                    else:
                        print(f"No clusters of similar files found with more than {threshold}% similarity in '{directory}'")
                else:
                    print(f"No files with more than {threshold}% similarity found in '{directory}'")
            else:
                print(f"No files with more than {threshold}% similarity found in '{directory}'")
        else:
            print(f"Error: {result.stderr}")

    except Exception as e:
        print(f"An error occurred: {str(e)}")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Search for similar files using ssdeep")
    parser.add_argument('directories', metavar='directory', type=str, nargs='*', 
                        help="Directory path(s) to search for similar files")
    parser.add_argument('-t', '--threshold', type=int, default=70, 
                        help="Similarity threshold (default is 70%)")

    # Parse the arguments
    args = parser.parse_args()

    # If no directories are provided as positional arguments, prompt interactively
    if not args.directories:
        directory_path = input("Enter the directory path to search for similar files: ")
        find_similar_files(directory_path, threshold=args.threshold)
    else:
        # Iterate through each directory provided as a positional argument
        for directory in args.directories:
            find_similar_files(directory, threshold=args.threshold)

if __name__ == "__main__":
    main()
