#!/bin/bash
# Path: scripts/sftp/remove-user.sh
# Author: Fokko Vos
#
# Removes a user from the sftp service and removes the volume for the user's folder from the compose file
# the sftp service is restarted after the user is removed to apply the changes
# does nothing if the user does not exist
#
# Flags:
#  --no-restart: do not restart the sftp service after the user is removed
#  --soft: do not throw an error if the user does not exist

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if [ ! -d "${INSTANCE_ROOT}" ]; then
    error "Create instances before adding sftp users"
fi

register_arg "user" "" "${FOLDER_REGEX}"

source "${SCRIPTS_DIR}/args.sh"

TARGET_FOLDER=$(jq -r --arg user "$ARG_USER" '.users[$user]' "$INDEX_FILE")

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

if [ -f "${SFTP_USERS_FILE}" ] && grep -q "^$ARG_USER:" "${SFTP_USERS_FILE}"; then
    (
        volume_to_remove=$(yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes[]" "${COMPOSE_FILE}" | grep ":/home/${USER}/*" | head -n 2)

        # remove user related volumes from the compose file
        for volume in "${volume_to_remove[@]}"; do
            if [[ ! -z "$volume" ]]; then
                yq e "del(.services.${COMPOSE_SFTP_SERVICE}.volumes[] | select(. == \"$volume\"))" -i "${COMPOSE_FILE}"
            fi
        done

        # remove the user's workspace zip file
        if [[ -f "${TARGET_FOLDER}/workspace_${ARG_USER}.zip" ]]; then
            rm -f "${TARGET_FOLDER}/workspace_${ARG_USER}.zip"
        fi

        # remove the user from the user file
        sed -i "/^$ARG_USER:/d" "${SFTP_USERS_FILE}"
        jq --arg user "$ARG_USER" 'del(.users[$user])' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

        # remove the user's key
        if [ -f "${SFTP_KEYS_DIR}/${USER}_id_ed25519_key" ]; then
            rm -f "${SFTP_KEYS_DIR}/${USER}_id_ed25519_key"
        fi

        # restart the instance (skip if --no-restart is set)
        if [ "${NO_RESTART}" != true ]; then
            restart "${COMPOSE_SFTP_SERVICE}" >/dev/null 2>&1
        fi
    ) &
    loading_spinner "Removing user $(mark "$ARG_USER") from ${COMPOSE_SFTP_SERVICE}..." \
        "Removed user $(mark "$ARG_USER") from ${COMPOSE_SFTP_SERVICE}"
else
    if [ "${SOFT}" != true ]; then
        error "User $ARG_USER does not exist"
    fi
fi
