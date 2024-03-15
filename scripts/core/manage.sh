#!/bin/bash
# Path: scripts/core/manage.sh
# Author: Fokko Vos
#
# This script is meant to manage instances
# the necessary information is requested from the user interactively using fuzzy search
# for quick actions also supports direct action execution without interactive selection
#
# FLAGS:
# --client: manage traefik client certificates instead of instances

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${SCRIPTS_DIR}/fuzzy.sh"

NO_PROMPT=true

register_arg "name" "" "${FOLDER_REGEX}"
register_arg "action" "" "${FOLDER_REGEX}"

source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

if [[ $FLAG_CLIENT = true ]]; then
    if [[ -z "${ARG_NAME}" ]]; then
        read -r ARG_NAME <<<$(select_client)
    fi

    if [[ -z "${ARG_NAME}" ]]; then
        error "No client selected"
    fi

    if [[ -z "${ARG_ACTION}" ]]; then
        read -r ARG_ACTION <<<$(select_client_action "${ARG_NAME}")
    fi

    if [[ -z "${ARG_ACTION}" ]]; then
        error "No action selected"
    fi

    case $ARG_ACTION in
    "revoke")
        bash "${SCRIPTS_DIR}/security/client-cert.sh" "${ARG_NAME}" --remove-only
        ;;
    "renew")
        bash "${SCRIPTS_DIR}/security/client-cert.sh" "${ARG_NAME}" --force
        ;;
    esac

else
    if [[ -z "${ARG_NAME}" ]]; then
        read -r ARG_NAME <<<$(select_instance)
    fi

    if [[ -z "${ARG_NAME}" ]]; then
        error "No instance selected"
    fi

    # determine the target type
    TARGET_TYPE="names"
    if [[ "${ARG_NAME}" =~ $DOMAIN_REGEX ]]; then
        TARGET_TYPE="domains"
    fi

    INSTANCE=$(get_instance "$TARGET_TYPE" "$ARG_NAME")

    # directory failsafe
    if [ ! -d "${INSTANCE}" ]; then
        error "The instance ${ARG_NAME} cannot be found"
    fi

    # get user selection if no action is provided
    if [ -z "${ARG_ACTION}" ]; then
        read -r ARG_ACTION <<<$(select_action "${INSTANCE}")
    fi

    if [ -z "${ARG_ACTION}" ]; then
        error "No action selected for the instance $(basename "${INSTANCE}")"
    fi

    # add .sh if not present
    if [[ ! "${ARG_ACTION}" == *.sh ]]; then
        ARG_ACTION="${ARG_ACTION}.sh"
    fi

    # action failsafe
    if [ ! -f "${INSTANCE}/${ARG_ACTION}" ]; then
        echo -e "${COLOR_RED}The action $(mark "${ARG_ACTION%.sh}")${COLOR_RED} does not exist for the instance $(mark "$(basename "${INSTANCE}")")"
        error "Available actions: $(get_available_actions "${INSTANCE}")"
    fi

    bash "${INSTANCE}/${ARG_ACTION}"
fi
