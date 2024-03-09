#!/bin/bash
# Path: scripts/sftp/remove-user.sh
# Author: Fokko Vos
#
# Removes a user from the sftp service and removes the volume for the user's folder from the compose file
# the sftp service is restarted after the user is removed to apply the changes
# does nothing if the user does not exist

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if [ $# -lt 1 ]; then
    error "Usage: $0 <username>"
fi

USER=$(echo "${1}" | awk '{print tolower($0)}')

if [ -f "${SFTP_USERS_FILE}" ] && grep -q "^$USER:" "${SFTP_USERS_FILE}"; then
    (
        volume_to_remove=$(yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes[]" "${COMPOSE_FILE}" | grep ":/home/${USER}/webroot" | head -n 1)

        if [[ ! -z "$volume_to_remove" ]]; then
            yq e "del(.services.${COMPOSE_SFTP_SERVICE}.volumes[] | select(. == \"$volume_to_remove\"))" -i "${COMPOSE_FILE}"
        fi

        sed -i "/^$USER:/d" "${SFTP_USERS_FILE}"
        if [ "${NORESTART}" != true ]; then
            restart_sftp >/dev/null 2>&1
        fi
    ) &
    loading_spinner "Removing user $(mark "$USER") from sftp..." \
        "Removed user $(mark "$USER") from sftp"
else
    if [ "${SOFT}" != true ]; then
        error "User $USER does not exist"
    fi
fi
