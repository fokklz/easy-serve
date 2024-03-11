#!/bin/bash
# Path: scripts/sftp/gen-host-key.sh
# Author: Fokko Vos
#
# Generates a new host key for the sftp service
# the key will be stored in the sftp/keys folder
#
# Flags:
#  --force: force the creation of the host key even if the key already exists

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if [ -f "${SFTP_KEYS_DIR}/ssh_host_ed25519_key" ]; then
    if [ "${FORCE}" != true ]; then
        if [ "${SOFT}" != true ]; then
            error "Host Key already exists, use --force to overwrite"
        fi
    else
        rm -f "${SFTP_KEYS_DIR}/ssh_host_ed25519_key"
    fi
fi

(
    ssh-keygen -t ed25519 -f "${SFTP_KEYS_DIR}/ssh_host_ed25519_key" -C "sftp.${DOMAIN}" -P "" >/dev/null 2>&1
) &
loading_spinner "Generating Host Key for $(mark "sftp.${DOMAIN}")..." \
    "Generated Host Key for $(mark "sftp.${DOMAIN}")\nHost Key: $(mark "${SFTP_KEYS_DIR}/sftp_host_ed25519_key")"
