#!/bin/bash

# Assuming /bin/bash is the default shell to restore
DEFAULT_SHELL=/bin/bash
TARGET_USERS_FILE="target_users"

# Read from the user_list file
while IFS= read -r user; do
    # Check if the user exists in /etc/passwd
    if grep -q "^$user:" /etc/passwd; then
        # Get the user's home directory and current shell
        user_dir=$(grep "^$user:" /etc/passwd | cut -d: -f6)
        user_shell=$(grep "^$user:" /etc/passwd | cut -d: -f7)

        # Modify the shell only if the current shell is not the default shell
        if [ "$user_shell" != "$DEFAULT_SHELL" ]; then
            # Change the user's shell back to bash
            usermod -s "$DEFAULT_SHELL" "$user"
            echo "Changed $user's shell back to $DEFAULT_SHELL"
        else
            echo "$user's shell is already $DEFAULT_SHELL"
        fi

        # Enter the user's directory
        if [ -d "$user_dir" ]; then
            pushd "$user_dir" > /dev/null
            # Check for .bashrc_bak, .bash_profile_bak, .profile_bak files and rename them back
            for file in .bashrc_bak .bash_profile_bak .profile_bak; do
                if [ -f "$file" ]; then
                    original_file="${file%_bak}"
                    # Move the file and rename it back to original
                    mv "$file" "$original_file"
                    echo "Restored $user's $file to $original_file"
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
