#!/bin/bash

TARGET_SHELL=/home/public_config/login.bash
TARGET_USERS_FILE="target_users"

# Read from the user_list file
while IFS= read -r user; do
    # Check if the user exists in /etc/passwd
    if grep -q "^$user:" /etc/passwd; then
        # Get the user's home directory and current shell
        user_dir=$(grep "^$user:" /etc/passwd | cut -d: -f6)
        user_shell=$(grep "^$user:" /etc/passwd | cut -d: -f7)

        # Modify the shell only if the current shell is not the target shell
        if [ "$user_shell" != "$TARGET_SHELL" ]; then
            # Change the user's shell to the target shell
            usermod -s "$TARGET_SHELL" "$user"
            echo "Changed $user's shell to $TARGET_SHELL"
        else
            echo "$user's shell is already $TARGET_SHELL"
        fi

        # Enter the user's directory
        if [ -d "$user_dir" ]; then
            pushd "$user_dir" > /dev/null
            # Check and rename .bashrc, .bash_profile, .profile files
            for file in .bashrc .bash_profile .profile; do
                if [ -f "$file" ]; then
                    # Record the original file permissions
                    original_perm=$(stat -c "%a" "$file")
                    
                    # Move the file and rename it
                    mv "$file" "${file}_bak"
                    echo "$user's $file has been renamed to ${file}_bak"
                    
                    # Apply the original permissions to the new file
                    chmod "$original_perm" "${file}_bak"
                fi
            done
            popd > /dev/null
        else
            echo "$user's home directory not found"
        fi
    else
        echo "User $user does not exist"
    fi
done < "$TARGET_USERS_FILE"
