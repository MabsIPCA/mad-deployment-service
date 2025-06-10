#!/bin/sh
set -e

# Check if TARGET_PATH is set
if [ -z "$TARGET_PATH" ]; then
    echo "Error: TARGET_PATH is not set!"
    exit 1
fi

# Ensure the target directory exists
mkdir -p "$TARGET_PATH"

# Check if the directory is emptyR
if [ -z "$(ls -A "$TARGET_PATH")" ]; then
    echo "Target directory is empty. Copying files..."
    cp -R /data/* "$TARGET_PATH"
    echo "Files copied successfully to $TARGET_PATH."
else
    echo "Target directory is not empty. Skipping copy."
fi