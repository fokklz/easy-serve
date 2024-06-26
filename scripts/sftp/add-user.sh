#!/bin/bash
# Path: scripts/sftp/add-user.sh
# Author: Fokko Vos
#
# Adds a user to the sftp service and creates a volume for the user's folder
# the user's key is generated and added to the sftp service as well
# the key will be stored in the sftp/keys folder prefixed with the user's name
#
# Flags:
#  --no-restart: do not restart the sftp service after the user is added
#  --force: force the creation of the user even if the user already exists

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if [ ! -d "${INSTANCE_ROOT}" ]; then
    error "Create instances before adding sftp users"
fi

register_arg "user" "" "${FOLDER_REGEX}"
register_arg "folder"

source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

# fix for faulty user file created by docker
if [ -d "$SFTP_USERS_FILE" ]; then
    rm -rf "$SFTP_USERS_FILE"
fi

# create a empty user file if it does not exist to ensure the sftp server start correctly
if [ ! -f "$SFTP_USERS_FILE" ]; then
    touch "$SFTP_USERS_FILE"
fi

# ensure the user does not already exist
if grep -q "^$ARG_USER:" "${SFTP_USERS_FILE}"; then
    if [ "$FORCE" = true ]; then
        bash "${DIR}/remove-user.sh" "$ARG_USER" --no-restart
    else
        error "User $ARG_USER already exists"
    fi
fi

USER_ID=10001

# extract all uids from the file and sort them so we can find the first unused one starting from 10001
uids=$(cut -d':' -f3 "${SFTP_USERS_FILE}" | sort -n)
while :; do
    if ! grep -q "^$USER_ID$" <<<"${uids}"; then
        break
    fi
    ((USER_ID++))
done

# add the volume to the docker-compose file
(
    if [ ! -d "${ARG_FOLDER}/webroot" ]; then
        mkdir -p "${ARG_FOLDER}/webroot"
    fi

    if [ ! -f "${ARG_FOLDER}/webroot/index.html" ]; then
        echo "<h1>Welcome to the workspace of $ARG_USER</h1>" >"${ARG_FOLDER}/webroot/index.html"
    fi

    ssh-keygen -t ed25519 -f "${SFTP_KEYS_DIR}/${ARG_USER}_id_ed25519_key" -C "${ARG_USER}" -P "" >/dev/null 2>&1

    # ensure the user has access to the folder
    chown -R $USER_ID:$USER_ID "${ARG_FOLDER}/webroot"
    chmod -R 755 "${ARG_FOLDER}/webroot"

    # add the webroot and the public key to the sftp service
    yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes += [\"${ARG_FOLDER}/webroot/:/home/${ARG_USER}/webroot\", \"${SFTP_KEYS_DIR}/${ARG_USER}_id_ed25519_key.pub:/home/${ARG_USER}/.ssh/keys/${ARG_USER}_id_ed25519_key.pub\"]" -i "${COMPOSE_FILE}" >/dev/null 2>&1

    # add the user with a empty password to the sftp users file - can only auth by key
    echo "$ARG_USER::$USER_ID:$USER_ID:webroot" >>$SFTP_USERS_FILE
    jq --arg user "$ARG_USER" --arg folder "$ARG_FOLDER" '.users += {($user): $folder}' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

    if [ "${NO_RESTART}" != true ]; then
        restart "${COMPOSE_SFTP_SERVICE}" >/dev/null 2>&1
    fi
) &

loading_spinner "Adding $(mark "$ARG_USER")..." \
    "Added $(mark "$ARG_USER")"

bash "${DIR}/create-workspace-zip.sh" "${ARG_USER}" "${ARG_FOLDER}/.."
