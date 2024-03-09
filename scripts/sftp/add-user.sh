#!/bin/bash
# Path: scripts/sftp/add-user.sh
# Author: Fokko Vos
#
# Adds a user to the sftp service and creates a volume for the user's folder
# the user's password is generated and printed to the console on creation

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

named_args "USER|lower" "FOLDER"

# fix for faulty user file created by docker
if [ -d "$SFTP_USERS_FILE" ]; then
    rm -rf "$SFTP_USERS_FILE"
fi

# create a empty user file if it does not exist to ensure the sftp server start correctly
# TODO: could be moved to a install script
if [ ! -f "$SFTP_USERS_FILE" ]; then
    touch "$SFTP_USERS_FILE"
fi

# ensure the user does not already exist
if grep -q "^$USER:" "${SFTP_USERS_FILE}"; then
    if [ "$FORCE" = true ]; then
        bash "${DIR}/remove-user.sh" "$USER" --norestart
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

    chown -R $USER_ID:$USER_ID "${FOLDER}"
    chmod -R 755 "${FOLDER}"
    yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes += [\"${FOLDER}/:/home/${USER}/webroot\"]" -i "${COMPOSE_FILE}" >/dev/null 2>&1
) &
loading_spinner "Adding volume for $(mark "$USER")..." \
    "Added volume for $(mark "$USER")"

password_info=$(docker run -i --rm atmoz/makepasswd --crypt-md5)

PASSWORD=$(echo "$password_info" | awk '{print $1}')
HASHED_PASSWORD=$(echo "$password_info" | awk '{print $2}')

# add the user to the sftp users file and restart the sftp service
(
    echo "$USER:$HASHED_PASSWORD:e:$USER_ID:$USER_ID:webroot" >>$SFTP_USERS_FILE
    restart "${COMPOSE_SFTP_SERVICE}" >/dev/null 2>&1
) &
loading_spinner "Adding user $(mark "$USER") to sftp..." \
    "Added user $(mark "$USER") to sftp\nPassword: $(mark "$PASSWORD")\nFolder: $(mark "$FOLDER")"

bash "${DIR}/create-workspace-zip.sh" "${USER}" "${PASSWORD}" --out="${FOLDER}/.."
