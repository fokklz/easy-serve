#!/bin/bash
# Path: scripts/instance/uninstall.sh
# Author: Fokko Vos
#
# This script is used to uninstall the instance
# the user is prompted for confirmation before the action is executed
#
# Flags:
#  --force: do not prompt for confirmation

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

named_args "name"

TARGET_TYPE="names"
if [[ "${name}" =~ $DOMAIN_REGEX ]]; then
    TARGET_TYPE="domains"
fi

INSTANCE=$(get_instance "${TARGET_TYPE}" "${name}")

source "${INSTANCE}/.env"

if prompt_confirmation "Are you sure you want to uninstall the instance ${INSTANCE_NAME} served at ${INSTANCE_DOMAIN}?"; then
    bash "${INSTANCE}/stop.sh"
    bash "${DIR}/../sftp/remove-user.sh" "${INSTANCE_NAME}" --soft
    rm -rf "${INSTANCE}"
else
    echo "Aborted."
fi
