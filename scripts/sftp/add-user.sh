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

named_args "USER|lower" "FOLDER"

# fix for faulty user file created by docker
if [ -d "$SFTP_USERS_FILE" ]; then
    rm -rf "$SFTP_USERS_FILE"
fi

# create a empty user file if it does not exist to ensure the sftp server start correctly
if [ ! -f "$SFTP_USERS_FILE" ]; then
    touch "$SFTP_USERS_FILE"
fi

# ensure the user does not already exist
if grep -q "^$USER:" "${SFTP_USERS_FILE}"; then
    if [ "$FORCE" = true ]; then
        bash "${DIR}/remove-user.sh" "$USER" --no-restart
    else
        error "User $USER already exists"
    fi
fi

USER_ID=1001

# extract all uids from the file and sort them so we can find the first unused one starting from 1001
uids=$(cut -d':' -f3 "${SFTP_USERS_FILE}" | sort -n)
while :; do
    if ! grep -q "^$USER_ID$" <<<"${uids}"; then
        break
    fi
    ((USER_ID++))
done

# add the volume to the docker-compose file
(
    if [ ! -d "${FOLDER}" ]; then
        mkdir -p "${FOLDER}"
    fi

    if [ ! -f "${FOLDER}/index.html" ]; then
        echo "<h1>Welcome to the workspace of $USER</h1>" >"${FOLDER}/index.html"
    fi

    ssh-keygen -t ed25519 -f "${SFTP_KEYS_DIR}/${USER}_id_ed25519_key" -C "${USER}" -P "" >/dev/null 2>&1

    # ensure the user has access to the folder
    chown -R $USER_ID:$USER_ID "${FOLDER}"
    chmod -R 755 "${FOLDER}"

    # add the webroot and the public key to the sftp service
    yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes += [\"${FOLDER}/:/home/${USER}/webroot\", \"${SFTP_KEYS_DIR}/${USER}_id_ed25519_key.pub:/home/${USER}/.ssh/keys/${USER}_id_ed25519_key.pub\"]" -i "${COMPOSE_FILE}" >/dev/null 2>&1

    # add the user with a empty password to the sftp users file - can only auth by key
    echo "$USER::$USER_ID:$USER_ID:webroot" >>$SFTP_USERS_FILE

    if [ "${NO_RESTART}" != true ]; then
        restart "${COMPOSE_SFTP_SERVICE}" >/dev/null 2>&1
    fi
) &

loading_spinner "Adding $(mark "$USER")..." \
    "Added $(mark "$USER")"

bash "${DIR}/create-workspace-zip.sh" "${USER}" "${FOLDER}/.."
