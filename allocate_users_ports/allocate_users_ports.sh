#!/bin/bash

# Path to the target file
target_file="/home/public_config/users_ports"

# Check if the file exists, if not, create it
if [ ! -f "$target_file" ]; then
    mkdir -p $(dirname "$target_file")
    touch "$target_file"
fi

# Empty the file content
> "$target_file"

# Get all users and corresponding UID from /etc/passwd, filtering users with UID strictly greater than 1000
grep ':x:[1-9][0-9]\{3,\}:' /etc/passwd | while IFS=':' read -r username _ uid _; do
    # Exclude users "nobody" and "jump"
    if [[ "$username" != "nobody" && "$username" != "jump" ]]; then
        # Calculate the port number
        let port=18000+uid-1000
        # Write the information to the target file
        echo "$username:$port" >> "$target_file"
    fi
done

echo "User port allocation completed, results saved in $target_file"
