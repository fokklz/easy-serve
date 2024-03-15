#!/bin/bash

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

(
    cd "${ROOT}"
    docker compose down
) &
loading_spinner "Stopping services..." "Stopped services"

bash "${DIR}/../security/panic.sh" --no-restart --force

# Remove all volumes
yq e ".services.${COMPOSE_SFTP_SERVICE}.volumes = [\"./sftp/keys/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro\", \"./sftp/users.conf:/etc/sftp/users.conf:ro\"]" -i "${COMPOSE_FILE}"

# Remove all users
rm -rf "${SFTP_USERS_FILE}"
touch "${SFTP_USERS_FILE}"

# Reset all keys
rm -rf "${SFTP_KEYS_DIR}"
mkdir -p "${SFTP_KEYS_DIR}"
ssh-keygen -t ed25519 -f "${SFTP_KEYS_DIR}/ssh_host_ed25519_key" -C "sftp.${DOMAIN}" -P "" >/dev/null 2>&1

# Ensure all instances are stopped
for type in "${INSTANCE_ROOT}"/*; do
    if [[ -d "$type" ]]; then
        type_name=$(basename "$type")

        for name in "$type_name"/*; do
            if [[ -d "$name" ]]; then
                # Run stop.sh for each instance
                bash "${INSTANCE_ROOT}/${type_name}/${name}/stop.sh"
            fi
        done
    fi
done

# Backup all instances
if prompt_confirmation "Do you want to backup all instances?"; then
    if [ -d "${INSTANCE_ROOT}" ]; then
        (
            # TODO: Add a real backup system
            cd "${INSTANCE_ROOT}"
            tar -czf "instances.tar.gz" * >/dev/null 2>&1

            DATE=$(date +"%Y-%m-%d-%H-%M-%S")

            if [ -f "instances.tar.gz" ]; then
                mv "instances.tar.gz" "${ROOT}/instances.${DATE}.tar.gz"
            fi
        ) &
        loading_spinner "Backing up..." "Backed up instances"
    fi
fi

(
    rm -rf "${INSTANCE_ROOT}"
    mkdir -p "${INSTANCE_ROOT}"
) &
loading_spinner "Removing instances..." "Removed instances"

(
    cd "${ROOT}"
    docker compose up -d >/dev/null 2>&1
) &
loading_spinner "Starting services..." "Started services"

bash "${DIR}/../security/gen-client-cert.sh" "admin"
