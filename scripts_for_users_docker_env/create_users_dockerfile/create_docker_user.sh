#!/bin/bash

# Check if the user_info file exists
USER_INFO_FILE="create_users_list"
if [ ! -f "$USER_INFO_FILE" ]; then
    echo "User info file $USER_INFO_FILE not found."
    exit 1
fi

# Read the user_info file and build a Docker image for each user
while IFS=: read -r USERNAME PASSWD
do
    # Define the image name
    IMAGE_NAME="${USERNAME}_lab_image:v1.2"

    # Check if the Docker image already exists
    if docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
        echo "Image $IMAGE_NAME already exists. Skipping..."
        continue # Skip the current user, proceed to the next one
    fi

    # Get UID and GID from the host machine to avoid conflict with system variables UID and GID
    USER_UID=$(id -u $USERNAME)
    USER_GID=$(id -g $USERNAME)

    # Check if USER_UID and USER_GID were successfully retrieved
    if [ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
        echo "Failed to get UID or GID for user $USERNAME"
        continue # Skip the current user, proceed to the next one
    fi

    # Build the Docker image using the retrieved information
    echo "Building image for $USERNAME with UID=$USER_UID, GID=$USER_GID"
    docker build --build-arg USERNAME=$USERNAME --build-arg PASSWD=$PASSWD --build-arg UID=$USER_UID --build-arg GID=$USER_GID -t $IMAGE_NAME .
done < "$USER_INFO_FILE"

echo "Finished processing all users."
