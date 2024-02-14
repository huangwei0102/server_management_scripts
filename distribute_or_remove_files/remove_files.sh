#!/bin/bash

# Define the path to the folder containing the files to distribute
TARGET_FOLDER="server_init_files"

# Path to the file with the list of target users and their home directories
TARGET_USERS_FILE="target_users"

# Read the target users file line by line
while IFS=':' read -r username home_dir; do
    # Check if the user's home directory exists
    if [ -d "$home_dir/$TARGET_FOLDER" ]; then
    # remove the target folder from the user's home directory
    sudo rm -r "$home_dir/$TARGET_FOLDER"
    echo "Target directory for $username has been removed."
    else
    echo "Target directory for $username does not exist: $home_dir/$TARGET_FOLDER"
    fi
done < "$TARGET_USERS_FILE"
