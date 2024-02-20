#!/bin/bash

# Path to the user_info file
USER_INFO_FILE="../users_init_info"

# Setting length of password
passwd_length_setting=16

# Generate a random strong password
generate_strong_password_naive() {
    tr -dc 'A-Za-z0-9_!@#$%^&*' < /dev/urandom | head -c 16
}

generate_strong_password() {
    local passwd_length=$passwd_length_setting
    # Check if the password length is less than 6 characters
    if [ "$passwd_length" -lt 6 ]; then
        echo "Password length must be at least 6 characters."
        return 1
    fi

    # Define character sets
    local upper_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lower_chars='abcdefghijklmnopqrstuvwxyz'
    local nums='0123456789'
    local special_chars='_!@#$%^&*'

    # Ensure the password contains all types of characters
    local password=$( \
        echo -n "$upper_chars" | fold -w1 | shuf | head -c1; \
        echo -n "$lower_chars" | fold -w1 | shuf | head -c1; \
        echo -n "$nums" | fold -w1 | shuf | head -c1; \
        echo -n "$special_chars" | fold -w1 | shuf | head -c1; \
        tr -dc 'A-Za-z0-9_!@#$%^&*' < /dev/urandom | head -c $(($passwd_length - 4)) \
    )

    # Shuffle the password to increase randomness
    echo "$password" | fold -w1 | shuf | tr -d '\n'
}


# Record the original owner and permissions
ORIGINAL_OWNER=$(stat -c "%U:%G" "$USER_INFO_FILE")
ORIGINAL_PERMS=$(stat -c "%a" "$USER_INFO_FILE")

# Backup the original file before modifications
cp "$USER_INFO_FILE" "${USER_INFO_FILE}.bak"

# Temporary file to store updated user info
TEMP_FILE=$(mktemp)

# Process each user information
while IFS=':' read -r username current_password; do
    # Generate a new strong password
    new_password=$(generate_strong_password)

    # Update the user's password in the system
    echo "$username:$new_password" | sudo chpasswd

    # Find user in users_init_info, delete their old password, and insert the new password
    awk -F: -v user="$username" -v passwd="$new_password" '{
        if ($1 == user) $2 = passwd;
        print $1 ":" $2;
    }' "$USER_INFO_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USER_INFO_FILE"

    echo "Password for $username changed to $new_password"
done < "$USER_INFO_FILE"

# Restore the original owner and permissions
sudo chown $ORIGINAL_OWNER "$USER_INFO_FILE"
sudo chmod $ORIGINAL_PERMS "$USER_INFO_FILE"

# Delete the backup file
rm "${USER_INFO_FILE}.bak"

echo "Backup file deleted."