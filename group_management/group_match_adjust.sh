#!/bin/bash

# Get all users with group ID greater than 1000
users=$(getent passwd | awk -F: '$3 >= 1000 {print $1}')

# Iterate over users
for user in $users; do
  # Extract username prefix
  prefix=$(echo $user | sed -E 's/([a-zA-Z]+).*/\1/')

  # Find other users with the same prefix
  for other_user in $users; do
    # Ignore the same user
    if [ "$user" == "$other_user" ]; then
      continue
    fi

    # Check if prefix is the same
    if [[ $other_user == $prefix* ]]; then
      # Add user to the other user's group
      echo "Adding $user to $other_user group"
      sudo usermod -a -G $other_user $user
    fi
  done
done

