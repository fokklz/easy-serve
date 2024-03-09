#!/bin/bash
# Path: scripts/security/gen-client-cert.sh
# Author: Fokko Vos
#
# Generates a client certificate for traefik dashboard authentication
# the certificate is signed by the CA certificate and key
# the password is automatically generated and printed on creation
# to authenticate the user will need to use the PFX certificate and the password

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${DIR}/vars.sh"

named_args "CLIENT_NAME|lower"

CERT_CN="${CLIENT_NAME}.client.traefik.${DOMAIN}"

# Ensure the CA certificate and key exist before generating the client certificate
if [ ! -f "${CA_CERT}" ] || [ ! -f "${CA_KEY}" ]; then
    bash "${DIR}/gen-ca-cert.sh"

    if [ $? -ne 0 ]; then
        error "Failed to generate CA certificate and key, cannot generate client certificate"
    fi
fi

# Create the directory for all client data
CLIENT_SUB_DIR="${CLIENTS_CERT_DIR}/${CLIENT_NAME}"
if [ ! -d "${CLIENT_SUB_DIR}" ]; then
    mkdir "${CLIENT_SUB_DIR}"
else
    # If the client directory already exists, re-create it if the force flag is set
    if [ "${FORCE}" = true ]; then
        rm -rf "${CLIENT_SUB_DIR}"
        mkdir "${CLIENT_SUB_DIR}"
    else
        error "Client ${CLIENT_NAME} already exists"
    fi
fi

CLIENT_CSR="${CLIENT_SUB_DIR}/${CLIENT_NAME}.traefik.client.csr"
CLIENT_CERT="${CLIENT_SUB_DIR}/${CLIENT_NAME}.traefik.client.crt"
CLIENT_KEY="${CLIENT_SUB_DIR}/${CLIENT_NAME}.traefik.client.key"

CLIENT_PASSWORD=$(openssl rand -hex 12)
CLIENT_PFX_CERT="${CLIENTS_CERT_DIR}/${CLIENT_NAME}.traefik.client.pfx"

(
    # Generate the client key and certificate
    openssl genrsa -out "${CLIENT_KEY}" 4096 >/dev/null 2>&1
    openssl req -new -key "${CLIENT_KEY}" -out "${CLIENT_CSR}" -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=${CERT_ORGANIZATION}/CN=${CERT_CN}" >/dev/null 2>&1
    openssl x509 -req -in "${CLIENT_CSR}" -CA "${CA_CERT}" -CAkey "${CA_KEY}" -CAcreateserial -out "${CLIENT_CERT}" -days 1024 -sha256 >/dev/null 2>&1

    # Generate PFX certificate using the generated password
    openssl pkcs12 -export -out "${CLIENT_PFX_CERT}" -inkey "${CLIENT_KEY}" -in "${CLIENT_CERT}" -passout "pass:${CLIENT_PASSWORD}" >/dev/null 2>&1
) &
loading_spinner "Generating Cert for Client $(mark "${CLIENT_NAME}")..." \
    "Generated Cert for Client $(mark "${CLIENT_NAME}")\nPFX Certificate: $(mark "${CLIENT_PFX_CERT}")\nPassword: $(mark "${CLIENT_PASSWORD}")"
