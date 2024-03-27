#!/bin/bash
# Path: scripts/instance/backup.sh
# Author: Fokko Vos
#
# This script is used to backup an instance

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

NO_PROMPT_NAME=true

register_arg "name" "" "${FOLDER_REGEX}"

source "${SCRIPTS_DIR}/args.sh"

source "${SCRIPTS_DIR}/utils/fuzzy.sh"

if [ -z "${ARG_NAME}" ]; then
    read -r ARG_NAME <<<$(select_instance)
fi

if [ -z "${ARG_NAME}" ]; then
    error "No instance selected"
fi

TARGET_TYPE="names"
if [[ "${ARG_NAME}" =~ $DOMAIN_REGEX ]]; then
    TARGET_TYPE="domains"
fi

INSTANCE=$(get_instance "${TARGET_TYPE}" "${ARG_NAME}")

source "${INSTANCE}/.env"

PROJECT_NAME="$(basename "$INSTANCE")"
PROJECT_COMPOSE_FILE="${INSTANCE}/docker-compose.yml"

BACKUP_TEMP_DIR="$(mktemp -d)"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

VOLUMES=$(yq e '.volumes | keys' "$PROJECT_COMPOSE_FILE" | awk -F' ' '{print $2}')

for volume in $VOLUMES; do
    custom_name=$(yq e ".volumes.${volume}.name" "$PROJECT_COMPOSE_FILE")

    # Check if the volume has a custom name
    if ! [[ -z "${custom_name}" || "${custom_name}" == "null" ]]; then
        volume_name="${custom_name}"
    else
        volume_name="${PROJECT_NAME}_${volume}"
    fi
    echo "Backing up volume ${volume_name}..."

    docker run --rm -v $volume_name:/volume/$volume -v $BACKUP_TEMP_DIR/volumes:/backup alpine cp -a /volume/$volume/. /backup/$volume

    echo "Done, location: $BACKUP_TEMP_DIR/volumes/$volume"
done
