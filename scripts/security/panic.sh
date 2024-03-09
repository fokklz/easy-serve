#!/bin/bash
DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if prompt_confirmation "Are you sure you want to revert all existing certificates and keys?"; then
    (
        rm -rf "${CERT_ROOT}"/*
    ) &
    loading_spinner "Removing existing certificates and keys..." "Removed existing certificates and keys"

    bash "${DIR}/gen-ca-cert.sh"
    bash "${DIR}/rotate-client-cert.sh"

    if [ "${NO_RESTART}" != "true" ]; then
        restart >/dev/null
    fi
else
    echo "Aborted."
fi
