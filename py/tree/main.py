#!/usr/bin/env python
import sys

def build_tree(dirs):
    tree = {}
    for d in sorted(dirs):
        parts = d.strip().split('/')
        current = tree
        for part in parts:
            if part not in current:
                current[part] = {}
            current = current[part]
    return tree


def print_tree(tree, level=0):
    for key, value in sorted(tree.items()):
        # Print the current directory/file
        print("|   " * level + "|-- " + key)
        if value:  # Recursively print subdirectories/files
            print_tree(value, level + 1)


def main():
    if len(sys.argv) != 2:
        print("Usage: ./create_tree <file>")
        return

    file_path = sys.argv[1]
    try:
        with open(file_path, "r") as file:
            dirs = file.readlines()
    except FileNotFoundError:
        print("Error: File not found")
        return

    # Build and print the directory tree structure
    tree = build_tree(dirs)
    print_tree(tree)


if __name__ == "__main__":
    main()
