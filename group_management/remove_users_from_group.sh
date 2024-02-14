#!/bin/bash

# Load configuration file
source ./users_group_config.sh

# Define function to check if a user exists
user_exists() {
    id "$1" &>/dev/null
}

# Define function to remove a user from a specified group
remove_user_from_group() {
    if user_exists "$1"; then
        # Remove user from the specified group
        sudo gpasswd -d "$1" "$GROUP_NAME"
        echo "User $1 removed from group $GROUP_NAME."
    else
        echo "User $1 does not exist. Skipping..."
    fi
}

# Process each provided username
for username in "${USERNAMES[@]}"; do
    echo "Processing $username..."
    remove_user_from_group "$username"
done

echo "All users processed."
