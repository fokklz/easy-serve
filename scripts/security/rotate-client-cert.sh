#!/bin/bash
# Path: scripts/security/rotate-client-cert.sh
# Author: Fokko Vos
#
# Overwrites the current client certifacte for system operations with a new one
# a PFX certificate is created and the password is stored alongside the path in the cert file located in the scripts directory
# the PFX file can then be used to authenticate with the traefik dashboard when using curl commands
#
# for example:
# curl --cert-type P12 --cert $(cat "${SEC_CERT}") https://traefik.fokklz.dev/api/rawdata
#
# Arguments: -
#
# Flags: -

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "${DIR}/../globals.sh"

output=$(bash "${DIR}/client-cert.sh" system --force --plain)

pfx_path=$(echo "$output" | grep -oP 'PFX Certificate: \K.*')
password=$(echo "$output" | grep -oP 'Password: \K.*')

echo "$pfx_path:$password" >"${SEC_CERT}"
