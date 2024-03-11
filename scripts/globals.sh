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

# Contains all arguments passed to the script not starting with --
ARGS=()

for arg in "$@"; do
    if [[ ! "$arg" =~ ^-- ]]; then
        ARGS+=("$arg")
    else
        IFS='=' read -r flag_name flag_value <<<"${arg:2}"
        if [ -z "$flag_value" ]; then
            flag_value=true
        fi

        flag_name="${flag_name//-/_}" # replace '-' with '_'
        flag_name="${flag_name^^}"    # uppercase

        declare -g "$flag_name"="$flag_value"
    fi
done

source "${SCRIPTS_DIR}/functions.sh"
# Assigns the arguments to the variables with the names provided
function named_args() {
    local i=0
    local min_length=0
    local usage=""
    local clean_args=()
    local modifier=()

    for arg in "${@}"; do
        # apply modifier if present
        if [[ "$arg" == *"|"* ]]; then
            IFS='|' read -r arg modifier <<<"$arg"
            modifier+=("${modifier,,}")
        else
            modifier+=("-")
        fi

        # when the name is uppercase, it is required
        if [[ "$arg" == *[[:upper:]]* ]]; then
            ((min_length++))
            usage+="<${arg,,}> "
        else
            usage+="[${arg,,}] "
        fi

        clean_args+=("$arg")
    done

    declare -g "COMMAND_USAGE=${usage}"
    if [ "${USAGE}" = true ]; then
        echo "${COMMAND_USAGE}"
        exit 0
    fi

    for name in "${clean_args[@]}"; do

        value="${ARGS[$i]}"

        if [ -z "${value}" ]; then
            break
        fi

        mod="${modifier[$i]}"
        if [ "${mod}" != "-" ]; then
            case "${mod}" in
            "lower")
                value="${value,,}"
                ;;
            "upper")
                value="${value^^}"
                ;;
            esac
        fi

        declare -g "${name}=${value}"
        unset value
        ((i++))
    done
}

ENSURE="$INSTANCE_ROOT $SFTP_KEYS_DIR $CLIENTS_CERT_DIR"

for dir in $ENSURE; do
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
    fi
done
