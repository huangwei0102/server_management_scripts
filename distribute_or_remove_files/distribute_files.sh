#!/bin/bash

# Define the path to the folder containing the files to distribute
SOURCE_FOLDER="/home/zkti/workspace"

# Path to the file with the list of target users and their home directories
TARGET_USERS_FILE="target_users"

# Read the target users file line by line
while IFS=':' read -r username home_dir; do
  # Check if the user's home directory exists
  if [ -d "$home_dir" ]; then
    # Copy the folder to the user's home directory
    sudo cp -r "$SOURCE_FOLDER" "$home_dir/"

    # Change the owner of the folder to the user
    sudo chown -R "$username:$username" "$home_dir/$(basename "$SOURCE_FOLDER")"
  else
    echo "Home directory for $username does not exist: $home_dir"
  fi
done < "$TARGET_USERS_FILE"
