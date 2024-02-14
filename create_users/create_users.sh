#!/bin/bash

# Define the path to the list of users to be created
create_users_list="./create_users_list"

# Define the path to store initial user information
users_init_info="../users_init_info"

# Define the user creation path
# home_path="/home/users" or data_path="/data/users"

create_path="/home"

# Function to generate a strong password
generate_strong_password() {
    tr -dc 'A-Za-z0-9_!@#$%^&*' < /dev/urandom | head -c 16
}

# Check if the create_users_list file exists
if [ ! -f "$create_users_list" ]; then
    echo "User information file does not exist: $create_users_list"
    exit 1
fi

# Check if users_init_info file exists, if not, create it
if [ ! -f "$users_init_info" ]; then
    touch "$users_init_info"
fi

# Read usernames from the create_users_list
while IFS= read -r new_user; do
    # Check if user already exists
    if id "$new_user" &>/dev/null; then
        echo "User $new_user already exists. Skipping."
        continue
    fi

    # Generate a strong password for the user
    user_password=$(generate_strong_password)

    # Create a new user with a home directory and specify the default shell
    useradd -d "${create_path}/${new_user}" -m -s '/bin/bash' "${new_user}"

    # Check if the user was successfully created
    if [ $? -eq 0 ]; then
        echo "User $new_user has been successfully created."

        # Set the user password
        echo "${new_user}:${user_password}" | chpasswd

        # (Optional) Add the user to additional groups, such as the sudo group
        # usermod -aG sudo "${new_user}"

        # Set home directory permissions
        chmod 750 "${create_path}/${new_user}"

        echo "User $new_user setup is completed."

        # Append the new user's information to users_init_info
        echo "${new_user}:${user_password}" >> "$users_init_info"
    else
        echo "Failed to create user: $new_user"
    fi
done < "$create_users_list"
