#!/bin/bash

# Docker daemon configuration file path
DAEMON_CONFIG="/etc/docker/daemon.json"

# Log options to be set
LOG_MAX_SIZE="10m"
LOG_MAX_FILE="3"

# Check if the Docker daemon configuration file exists
if [ ! -f "$DAEMON_CONFIG" ]; then
    echo "{}" | sudo tee $DAEMON_CONFIG > /dev/null
fi

# Backup the original daemon.json file and capture owner/group
DAEMON_CONFIG_BAK="${DAEMON_CONFIG}.bak"
sudo cp "$DAEMON_CONFIG" "$DAEMON_CONFIG_BAK"
ORIGINAL_OWNER=$(stat -c '%U:%G' "$DAEMON_CONFIG")

# Set log options using Python
python3 -c "
import json
with open('$DAEMON_CONFIG', 'r') as file:
    config = json.load(file)
config['log-driver'] = 'json-file'
config['log-opts'] = {'max-size': '$LOG_MAX_SIZE', 'max-file': '$LOG_MAX_FILE'}
with open('$DAEMON_CONFIG', 'w') as file:
    json.dump(config, file, indent=4)
"

# Restore original owner/group to daemon.json
sudo chown "$ORIGINAL_OWNER" "$DAEMON_CONFIG"

# Restart Docker service to apply changes
echo "Restarting Docker service to apply log configuration..."
sudo systemctl restart docker

# Cleanup: Remove backup files
sudo rm -f "$DAEMON_CONFIG_BAK"

echo "Docker log size limit has been set to $LOG_MAX_SIZE with $LOG_MAX_FILE rotated files."
