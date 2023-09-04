#!/bin/bash

# Define password policy variables
MIN_LENGTH=8
COMPLEXITY_REGEX="^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%^&*])"
MAX_HISTORY=3
MAX_LOGIN_ATTEMPTS=3
PASSWORD_EXPIRATION_DAYS=90

# Get the list of user accounts
USERS=$(cat /etc/passwd | cut -d: -f1)

for USER in $USERS; do
    # Check password length
    PASSWORD_LENGTH=$(sudo passwd -S $USER | awk '{print $2}')
    if [ $PASSWORD_LENGTH -lt $MIN_LENGTH ]; then
        echo "User $USER: Password does not meet the minimum length requirement."
    fi

    # Check password complexity
    PASSWORD=$(sudo cat /etc/shadow | grep $USER | cut -d: -f2)
    if ! [[ $PASSWORD =~ $COMPLEXITY_REGEX ]]; then
        echo "User $USER: Password does not meet complexity requirements."
    fi

    # Check password history
    PASSWORD_HISTORY=$(sudo cat /etc/security/opasswd | grep -o $USER | wc -l)
    if [ $PASSWORD_HISTORY -gt $MAX_HISTORY ]; then
        echo "User $USER: Password has been used too frequently."
    fi

    # Check password expiration
    PASSWORD_CHANGE_DATE=$(sudo passwd -S $USER | awk '{print $3}')
    DAYS_SINCE_CHANGE=$(( ( $(date +%s) - $PASSWORD_CHANGE_DATE ) / 86400 ))
    if [ $DAYS_SINCE_CHANGE -gt $PASSWORD_EXPIRATION_DAYS ]; then
        echo "User $USER: Password has expired. Please change it."
    fi

    # Implement account lockout policy
    FAILED_LOGIN_ATTEMPTS=$(sudo cat /var/log/auth.log | grep "Failed password for $USER" | wc -l)
    if [ $FAILED_LOGIN_ATTEMPTS -gt $MAX_LOGIN_ATTEMPTS ]; then
        echo "User $USER: Account locked due to too many failed login attempts."
        sudo usermod -L $USER
    fi
done
