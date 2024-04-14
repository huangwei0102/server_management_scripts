#!/bin/bash

IP=$(hostname -I | cut -d" " -f1)
# Extract the last three digits of the IP address
container_suffix=$(echo "$IP" | grep -oE '[^.]+$')

# Path to the file containing usernames
users_list='./create_users_containers_list'
# Path to the file containing user ports configuration
users_ports='/home/public_config/users_ports'

# Check if the files exist
if [ ! -f "$users_list" ] || [ ! -f "$users_ports" ]; then
    echo "User list file or ports file does not exist."
    exit 1
fi

# Read usernames line by line
while IFS= read -r user; do
    # Find the corresponding user's port from the ports configuration file
    port=$(grep "$user:" "$users_ports" | cut -d ':' -f2)
    if [ -z "$port" ]; then
        echo "Port number for user $user not found."
        continue
    fi

    # Check if the container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_suffix}server$"; then
        echo "Container for ${container_suffix}server already exists. Skipping..."
        continue
    fi

    container_name="server${container_suffix}"
    
    echo "Creating a Docker container for user $user, port number $port..."
    docker run --name "$user" --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -p "$port":22 -t -d -h "$container_name" -v "/data/users/$user/workspace:/home/$user/workspace" "${user}_lab_image:v1.2"
done < "$users_list"

echo "Docker containers for all users have been created or were already present."
