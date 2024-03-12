#!/bin/bash
# Path: scripts/globals.sh
# Author: Fokko Vos
#
# This file contains global variables and funcctions which are used to streamline the scripts

SCRIPTS_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "${SCRIPTS_DIR}/colors.sh"

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

# NAMES
# The pattern matches names that consist of alphanumeric characters, underscores, and hyphens.
# The name cannot be empty.
NAME_REGEX="^[A-Za-z0-9_-]+$"

if [ -f "${ROOT}/.env" ]; then
    source "${ROOT}/.env"
fi

CERT_COUNTRY="CH"
CERT_STATE="Basel"
CERT_CITY="Basel"
CERT_ORGANIZATION="${DOMAIN//./-}"

source "${SCRIPTS_DIR}/functions.sh"

# Contains all arguments passed to the script not starting with --
ARGS=()

for arg in "$@"; do
    if [[ "$arg" =~ ^-- ]]; then
        # Long option
        IFS='=' read -r flag_name flag_value <<<"${arg:2}"
        # Default flag value to true if not specified
        [ -z "$flag_value" ] && flag_value=true
    elif [[ "$arg" =~ ^-[^-] ]]; then
        # Short option
        short_opt="${arg:1}"
        long_opt=$(map_short_options "$short_opt")
        # Assuming the format -o=value for short options mapped to long options
        if [[ "$long_opt" =~ = ]]; then
            IFS='=' read -r flag_name flag_value <<<"$long_opt"
        else
            flag_name="${long_opt:2}"
            flag_value=true
        fi
    else
        # Not an option, add to ARGS array
        ARGS+=("$arg")
        continue
    fi

    # Replace '-' with '_' and uppercase the flag name
    flag_name="${flag_name//-/_}"
    flag_name="${flag_name^^}"

    if [ -z "$flag_name" ]; then
        continue
    fi

    # Declare the variable globally
    declare -g "FLAG_$flag_name=$flag_value"
done

ENSURE="$INSTANCE_ROOT $SFTP_KEYS_DIR $CLIENTS_CERT_DIR"

for dir in $ENSURE; do
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
    fi
done
