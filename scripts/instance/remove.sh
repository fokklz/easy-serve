#!/bin/bash
# Path: scripts/instance/uninstall.sh
# Author: Fokko Vos
#
# This script is used to uninstall the instance
# the user is prompted for confirmation before the action is executed
#
# Arguments:
#  name: the name of the instance to uninstall
#
# Flags:
#  --force: do not prompt for confirmation

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

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

if prompt_confirmation "Are you sure you want to uninstall the instance ${INSTANCE_NAME} served at ${INSTANCE_DOMAIN}?"; then
    bash "${INSTANCE}/stop.sh"
    bash "${DIR}/../sftp/remove-user.sh" "${INSTANCE_NAME}" --soft
    rm -rf "${INSTANCE}"
else
    echo "Aborted."
fi
