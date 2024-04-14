#!/bin/bash
# save as /public/login.bash
# give execute permission to everyone: chmod a+x /public/login.bash

USER_PORTS_FILE="/home/public_config/users_ports"

IP=$(hostname -I | cut -d" " -f1)
PORT=$(grep "^$USER:" $USER_PORTS_FILE | cut -d':' -f2)

function check_port_exis() {
    if [ -n "$PORT" ]; then
        echo "User: $USER"
        echo "Port: $PORT"
    else
        echo "Port for user $USER not found."
    fi
}


# Retrieving the container's IP address for reference, assuming the container uses the default bridge network
function get_container_ip_address() {
    local container_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$USER")
    if [[ -z "$container_ip" ]]; then
        echo "Failed to get your container's IP."
        echo "If this problem cannot be solved by retrying, please contact administrators."
        exit 1
    else
        echo "Container IP: $container_ip"
    fi
}


function check_container_exists() {
    # Check if the container exists
    docker inspect $USER &>/dev/null
    if [ $? -ne 0 ]; then
        echo "========== The container named $USER does not exist."
        echo "========== Please check the container name or contact administrators."
        exit 1
    fi
}


function check_container_running() {
    local container_status=$(docker inspect --format="{{.State.Running}}" "$USER" 2>/dev/null)
    
    if [ "$container_status" = "true" ]; then
        return 0
    else
        return 1
    fi
}


function print_help() {
    echo "========== Tips:"
    printf "Start your container: \e[96;1mssh $USER@$IP\e[0m\n"
    printf "Login your container: \e[96;1mssh $USER@$IP -p $PORT\e[0m\n"
    printf "Use \e[96;1mscp\e[0m or \e[96;1mSFTP\e[0m to transfer data to your container\n"
    printf "See GPU load: \e[96;1mnvidia-smi\e[0m\n"
    echo "========== End."
}


function do_start() {
    check_container_exists
    
    if ! check_container_running; then
        echo "========== Your container is not running"
        echo "========== Starting your container..."
        docker start "$USER"
        if [ $? -ne 0 ]; then
            echo "========== Fail. Please contact administrators"
            exit 1
        fi
        echo "========== Container started successfully."
        sleep 2 # Wait for the container to start

        # get_container_ip_address
        echo "Container IP: $IP"
    else
        echo "========== Your container is already running."
    fi
}


function do_stop() {
    check_container_exists

    if check_container_running; then
        echo "========== Stopping your container..."

        # get_container_ip_address
        echo "Container IP: $IP"

        # Stop the Docker container
        docker stop $USER

        echo "========== Container stopped successfully."
    else
        echo "========== Your container is already stopped."  
    fi

    # # Optional: Display the current state of the container to verify it has been stopped
    # docker inspect --format='{{.State.Status}}' $USER
}


function ssh_to_container() {
    check_container_exists

    if ! check_container_running; then
        echo "Container is not running. Starting container to SSH..."
        do_start
    fi
     ssh ${USER}@${IP} -p ${PORT}
}


function add_pubkey() {
    # Check if the container exists and is running
    check_container_exists

    if ! check_container_running; then
        echo "Container is not running. Starting container to add public key..."
        do_start
    fi

    # Read the user's inputted public key
    echo "========== Please paste your public key here:"
    read pubkey

    # Prepare the host's ~/.ssh directory and authorized_keys file
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys  # Ensure the file exists before appending
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    echo "$pubkey" >> ~/.ssh/authorized_keys
    echo "========== Public key added to host successfully."

    # Prepare the container's ~/.ssh directory and authorized_keys file
    docker exec $USER mkdir -p /home/$USER/.ssh
    docker exec $USER touch /home/$USER/.ssh/authorized_keys  # Ensure the file exists
    docker exec $USER chmod 700 /home/$USER/.ssh
    docker exec $USER chmod 600 /home/$USER/.ssh/authorized_keys
    echo "$pubkey" | docker exec -i $USER bash -c "cat >> /home/"$USER"/.ssh/authorized_keys"
    echo "========== Public key added to container successfully."
}


function remove_pubkey() {
    # Check if the container exists and is running
    check_container_exists

    if ! check_container_running; then
        echo "Container is not running. Starting container to remove public key..."
        do_start
    fi

    # Read the user's public key to be removed
    echo "========== Please paste the public key you wish to remove:"
    read pubkey

    # Escape special characters in pubkey to safely use it in sed pattern
    escaped_pubkey=$(printf '%s\n' "$pubkey" | sed -e 's/[\/&]/\\&/g')

    # Check and remove the public key from the host's ~/.ssh/authorized_keys
    if grep -q "^$escaped_pubkey\$" ~/.ssh/authorized_keys; then
        sed -i "/^$escaped_pubkey\$/d" ~/.ssh/authorized_keys
        echo "========== Public key removed from host successfully."
    else
        echo "No matching public key found in host."
    fi

    # Check and remove the public key from the container
    if docker exec -i $USER bash -c "grep -q \"^$escaped_pubkey\$\" /home/$USER/.ssh/authorized_keys"; then
        docker exec -i $USER bash -c "sed -i \"/^$escaped_pubkey\$/d\" /home/$USER/.ssh/authorized_keys"
        echo "========== Public key removed from container successfully."
    else
        echo "No matching public key found in container."
    fi
}


function display_pubkey() {
    # Check if the container exists
    check_container_exists

    echo "========== Displaying public keys from the host..."
    cat ~/.ssh/authorized_keys

    if ! check_container_running; then
        echo "Container is not running. Starting container to display public keys from the container."
        do_start
    else
        echo "========== Displaying public keys from the container..."
        docker exec -i $USER  bash -c "cat /home/"$USER"/.ssh/authorized_keys"
    fi
}


function do_host_passwd() {
    echo "========== Changing password in the host..."
    passwd "$USER"
}


function do_container_passwd() {
    # Check if the container exists and is running
    check_container_exists

    if ! check_container_running; then
        echo "Container is not running. Starting container to change ${USER} container password..."
        do_start
    fi

    echo "========== Changing password in your container..."
    docker exec -i "$USER" passwd "$USER"
}


print_help


while true; do
    echo "Please select an operation (Enter the number):"
    echo "0. Display help"
    echo "1. Start docker container"
    echo "2. Stop docker container"
    echo "3. SSh to docker container"
    echo "4. Change host's password"
    echo "5. Change docker container's password"
    echo "6. Add pubkey to host & docker container"
    echo "7. Remove pubkey from host & docker container"
    echo "8. Display pubkey from host & docker container"
    echo "9. Exit"
    read -p "Enter option: " option
    case $option in
        0) print_help ;;
        1) do_start ;;
        2) do_stop ;;
        3) ssh_to_container ;;
        4) do_host_passwd ;;
        5) do_container_passwd ;;
        6) add_pubkey ;;
        7) remove_pubkey ;;
        8) display_pubkey ;;
        9) break ;;
        *) echo "Invalid option, please enter again!" ;;
    esac
done