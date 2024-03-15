#!/bin/bash
# Path: scripts/security/gen-ca-cert.sh
# Author: Fokko Vos
#
# Generates a CA certificate which will be used to sign client certificates
# this is used for traefik dashboard authentication
#
# Flags:
#  --force: force the creation of the CA certificate even if the certificate already exists

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

if [ -f "${CA_CERT}" ] || [ -f "${CA_KEY}" ]; then
    if [[ $FLAG_FORCE = true ]]; then
        (
            rm -f "${CA_CERT}" "${CA_KEY}" >/dev/null 2>&1
        ) &
        loading_spinner "Removing existing CA for $(mark "${DOMAIN}")..." \
            "Removed existing CA for $(mark "${DOMAIN}")"
    else
        error "CA certificate and key already exist, use --force to overwrite"
    fi
fi

(
    openssl genrsa -out "${CA_KEY}" 4096 >/dev/null 2>&1
    openssl req -x509 -new -nodes -key "${CA_KEY}" -sha256 -days 1024 -out "${CA_CERT}" -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=${CERT_ORGANIZATION}/CN=${DOMAIN}" >/dev/null 2>&1
) &
loading_spinner "Generating CA for $(mark "${DOMAIN}")..." \
    "Generated CA for $(mark "${DOMAIN}")\nCA Certificate: $(mark "${CA_CERT}")\nCA Key: $(mark "${CA_KEY}")"
