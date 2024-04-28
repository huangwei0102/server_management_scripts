#!/bin/bash

# Setting length of password
passwd_length_setting=16

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

generate_strong_password