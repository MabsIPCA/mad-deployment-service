#!/bin/sh
set -e

# Check if TARGET_PATH is set
if [ -z "$TARGET_PATH" ]; then
    echo "Error: TARGET_PATH is not set!"
    exit 1
fi

# Ensure the target directory exists
mkdir -p "$TARGET_PATH"

# Copy all files from the container’s /data to the mounted volume
cp -R /data/* "$TARGET_PATH"

echo "Files copied successfully to $TARGET_PATH."
