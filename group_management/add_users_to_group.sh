#!/bin/bash

# Load configuration file
source ./users_group_config.sh

# Define function to add a user to a specified group
add_user_to_group() {
    username="$1"
    
    # Check if the user exists
    if id "$username" &>/dev/null; then
        echo "Adding $username to $GROUP_NAME group..."
        sudo usermod -aG "$GROUP_NAME" "$username"
    else
        echo "User $username does not exist. Skipping..."
    fi
}

# Process each provided username
for username in "${USERNAMES[@]}"; do
    add_user_to_group "$username"
done

echo "All done."
