#!/bin/bash
# Path: scripts/security/client-cert.sh
# Author: Fokko Vos
#
# Generates a client certificate for traefik dashboard authentication
# the certificate is signed by the CA certificate and key
# the password is automatically generated and printed on creation
# to authenticate the user will need to use the PFX certificate and the password
#
# Flags:
#  --force: force the creation of the client certificate even if the certificate already exists
#  --remove-only: only remove the client certificate if it exists

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

register_arg "name" "" "${FOLDER_REGEX}"

source "${SCRIPTS_DIR}/args.sh"

CERT_CN="${ARG_NAME}.client.traefik.${DOMAIN}"
CLIENT_SUB_DIR="${CLIENTS_CERT_DIR}/${ARG_NAME}"

CLIENT_CSR="${CLIENT_SUB_DIR}/${ARG_NAME}.traefik.client.csr"
CLIENT_CERT="${CLIENT_SUB_DIR}/${ARG_NAME}.traefik.client.crt"
CLIENT_KEY="${CLIENT_SUB_DIR}/${ARG_NAME}.traefik.client.key"

CLIENT_PASSWORD=$(openssl rand -hex 12)
CLIENT_PFX_CERT="${CLIENTS_CERT_DIR}/${ARG_NAME}.traefik.client.pfx"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

# Ensure the CA certificate and key exist before generating the client certificate
if [ ! -f "${CA_CERT}" ] || [ ! -f "${CA_KEY}" ]; then
    warning "CA certificate and key not found, generating..."
    bash "${DIR}/gen-ca-cert.sh"

    if [ $? -ne 0 ]; then
        error "Failed to generate CA certificate and key, cannot generate client certificate"
    fi
fi

# If the client certificate already exists, remove it if the force flag is set (or remove-only)
if [ -f "${CLIENT_PFX_CERT}" ]; then
    if [[ $FLAG_FORCE = true ]] || [[ $FLAG_REMOVE_ONLY = true ]]; then
        (
            rm -f "${CLIENT_PFX_CERT}"

            if [ -d "${CLIENT_SUB_DIR}" ]; then
                rm -rf "${CLIENT_SUB_DIR}"
            fi
        ) &
        loading_spinner "Removing client $(mark "${ARG_NAME}")..." \
            "Removed client $(mark "${ARG_NAME}")"
    else
        error "PFX certificate for client ${ARG_NAME} already exists"
    fi
fi

# Force exit on remove-only flag
if [[ $FLAG_REMOVE_ONLY = true ]]; then
    exit 0
fi

(
    # Generate the client key and certificate
    openssl genrsa -out "${CLIENT_KEY}" 4096 >/dev/null 2>&1
    openssl req -new -key "${CLIENT_KEY}" -out "${CLIENT_CSR}" -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=${CERT_ORGANIZATION}/CN=${CERT_CN}" >/dev/null 2>&1
    openssl x509 -req -in "${CLIENT_CSR}" -CA "${CA_CERT}" -CAkey "${CA_KEY}" -CAcreateserial -out "${CLIENT_CERT}" -days 1024 -sha256 >/dev/null 2>&1

    # Generate PFX certificate using the generated password
    openssl pkcs12 -export -out "${CLIENT_PFX_CERT}" -inkey "${CLIENT_KEY}" -in "${CLIENT_CERT}" -passout "pass:${CLIENT_PASSWORD}" >/dev/null 2>&1
) &
loading_spinner "Generating Cert for Client $(mark "${ARG_NAME}")..." \
    "Generated Cert for Client $(mark "${ARG_NAME}")\nPFX Certificate: $(mark "${CLIENT_PFX_CERT}")\nPassword: $(mark "${CLIENT_PASSWORD}")"
