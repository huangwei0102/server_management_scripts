#!/bin/bash

# Define the output file where usernames and home paths will be saved
output_file="username_homepath"

# Check if the output file already exists and remove it to avoid appending to old data
[ -f "$output_file" ] && rm "$output_file"

# Read from /etc/passwd
while IFS=':' read -r username _ uid _ _ homepath _; do
    # Check if UID is greater than 1000 and username is not "nobody"
    if [ "$uid" -gt 1000 ] && [ "$username" != "nobody" ]; then
        # Write username and home path to the output file
        echo "${username}:${homepath}" >> "$output_file"
    fi
done < /etc/passwd

echo "Usernames and home paths have been written to $output_file."
