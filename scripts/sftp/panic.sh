#!/bin/bash
# Path: scripts/security/panic.sh
# Author: Fokko Vos
#
# This script is used to revert all existing certificates and keys
# the user is prompted for confirmation before the action is executed
#
# Arguments: -
#
# Flags:
#  --no-restart: do not restart the services after the certificates and keys have been reverted

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

if prompt_confirmation "Are you sure you want to revert all existing certificates and keys for SFTP?"; then
    (
        rm -rf "${SFTP_KEYS_DIR}"/*
    ) &
    loading_spinner "Removing existing certificates and keys..." "Removed existing certificates and keys"

    bash "${SCRIPTS_DIR}/sftp/gen-host-key.sh" ${@:1}
    # TODO: create a new key for each user and update the workspace.zip file

    if [[ "${FLAG_NO_RESTART}" != true ]]; then
        restart >/dev/null
    fi
else
    echo "Aborted."
fi
