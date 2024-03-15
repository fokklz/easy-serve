#!/bin/bash
# Path: scripts/globals.sh
# Author: Fokko Vos
#
# This file contains global variables and funcctions which are used to streamline the scripts

SCRIPTS_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "${SCRIPTS_DIR}/colors.sh"

ARG_NAMES=()
declare -A ARG_SPECS

# Helper function to register arguments for a script to auto-prompt the user for missing arguments
# the script will try to use a named validation function using `is_valid_${name}` to validate the input
# if the validation function does not exist, the regex will be used to validate the input
# if the regex & no function is not provided, the input will not be validated
# a default value will be used if the user does not provide a value and turns the variable to be "required"
function register_arg() {
    local name="$1"

    ARG_NAMES+=("$name")

    ARG_SPECS["$name, default"]=$2
    ARG_SPECS["$name, regex"]=$3
}

# Root directories
ROOT=$(dirname "${SCRIPTS_DIR}")
TEMPLATE_ROOT="${ROOT}/templates"
INSTANCE_ROOT="${ROOT}/instances"
CERT_ROOT="${ROOT}/certs"
SFTP_ROOT="${ROOT}/sftp"

# Compose information
COMPOSE_FILE="${ROOT}/docker-compose.yml"
COMPOSE_SFTP_SERVICE="sftp"

# Certificates
SEC_CERT="${CERT_ROOT}/cert"
CLIENTS_CERT_DIR="${CERT_ROOT}/clients"
CA_CERT="${CERT_ROOT}/ca.crt"
CA_KEY="${CERT_ROOT}/ca.key"

# SFTP information
SFTP_USERS_FILE="${SFTP_ROOT}/users.conf"
SFTP_KEYS_DIR="${SFTP_ROOT}/keys"

# Instance information
INDEX_FILE="${INSTANCE_ROOT}/index.json"

# REGEX patterns

# DOMAINS
# The pattern matches domain names that consist of one or more segments separated by periods.
# Each segment can contain alphanumeric characters and hyphens, but cannot start or end with a hyphen.
# The top-level domain (TLD) must consist of two or more alphabetical characters.
DOMAIN_REGEX="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\.[A-Za-z]{2,}$"

# FOLDERS
# The pattern matches folder names that consist of alphanumeric characters, underscores, and hyphens.
# The folder name cannot be empty.
FOLDER_REGEX="^[A-Za-z0-9_-]+$"

if [ -f "${ROOT}/.env" ]; then
    source "${ROOT}/.env"
fi

CERT_COUNTRY="CH"
CERT_STATE="Basel"
CERT_CITY="Basel"
CERT_ORGANIZATION="${DOMAIN//./-}"

source "${SCRIPTS_DIR}/validators.sh"
source "${SCRIPTS_DIR}/functions.sh"

ENSURE="$INSTANCE_ROOT $SFTP_KEYS_DIR $CLIENTS_CERT_DIR"

for dir in $ENSURE; do
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
    fi
done
