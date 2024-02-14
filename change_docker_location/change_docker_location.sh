#!/bin/bash

# Set the new Docker storage path
NEW_DOCKER_PATH="/data"
# Define the original Docker data path
ORIGINAL_DOCKER_DATA_PATH="/var/lib/docker"

# Verify new Docker path is not in root
if [[ "$NEW_DOCKER_PATH" == "/"* ]]; then
    echo "It's unsafe to use a root directory. Please specify a subdirectory." >&2
    exit 1
fi

# Stop the Docker service
echo "Stopping Docker service..."
if ! sudo systemctl stop docker; then
    echo "Failed to stop Docker service. Exiting..." >&2
    exit 1
fi

# Create the new Docker storage directory
echo "Creating new Docker directory at $NEW_DOCKER_PATH..."
if ! sudo mkdir -p "$NEW_DOCKER_PATH"; then
    echo "Failed to create Docker directory. Exiting..." >&2
    exit 1
fi

# Check if /etc/docker/daemon.json file exists and back it up
DAEMON_CONFIG="/etc/docker/daemon.json"
if [ -f "$DAEMON_CONFIG" ]; then
    echo "Backing up existing Docker daemon configuration..."
    if ! sudo cp "$DAEMON_CONFIG" "${DAEMON_CONFIG}.bak"; then
        echo "Failed to backup Docker daemon configuration. Exiting..." >&2
        exit 1
    fi
else
    echo "{}" | sudo tee "$DAEMON_CONFIG" > /dev/null # Ensure file exists and is valid JSON
fi

# Update Docker's configuration to use the new storage path
echo "Updating Docker configuration to use new storage path..."
sudo python -c "import json; fp='$DAEMON_CONFIG'; data=json.load(open(fp)); data['data-root']='$NEW_DOCKER_PATH'; json.dump(data, open(fp, 'w'), indent=4)"

# Set the correct permissions and owner for daemon.json
sudo chown root:root "$DAEMON_CONFIG"
sudo chmod 644 "$DAEMON_CONFIG"

# Move existing Docker data to the new location
echo "Moving existing Docker data to the new location..."
if ! sudo mv "$ORIGINAL_DOCKER_DATA_PATH" "$NEW_DOCKER_PATH"; then
    echo "Failed to move Docker data. Exiting..." >&2
    exit 1
fi

# Start the Docker service
echo "Starting Docker service..."
if ! sudo systemctl start docker; then
    echo "Failed to start Docker service. Please check the Docker service status." >&2
    exit 1
fi

echo "Docker storage location has been changed to $NEW_DOCKER_PATH."
