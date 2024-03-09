#!/bin/bash
# Path: scripts/security/gen-host-ca.sh
# Author: Fokko Vos
#

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

(
    ssh-keygen -t ed25519 -f "${SFTP_KEYS_DIR}/ssh_host_ed25519_key" -C "sftp.${DOMAIN}" -P "" >/dev/null 2>&1
) &
loading_spinner "Generating Host Key for $(mark "sftp.${DOMAIN}")..." \
    "Generated Host Key for $(mark "sftp.${DOMAIN}")\nHost Key: $(mark "${SFTP_KEYS_DIR}/ssh_host_ed25519_key")"
