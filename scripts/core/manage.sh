#!/bin/bash
# Path: scripts/core/manage.sh
# Author: Fokko Vos
#
# This script is meant to manage instances
# the necessary information is requested from the user interactively using fuzzy search
# for quick actions also supports direct action execution without interactive selection

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${DIR}/../fuzzy.sh"

named_args "instance" "action"

if [[ $FLAG_CLIENT = true ]]; then
    if [ -z "${instance}" ]; then
        read -r instance <<<$(select_client)
    fi

    if [ -z "${instance}" ]; then
        error "No client selected"
    fi

    if [ -z "${action}" ]; then
        read -r action <<<$(select_client_action "${instance}")
    fi

    if [ -z "${action}" ]; then
        error "No action selected"
    fi

    case $action in
    "revoke")
        bash "${SCRIPTS_DIR}/security/client-cert.sh" "${instance}" --remove-only
        ;;
    "renew")
        bash "${SCRIPTS_DIR}/security/client-cert.sh" "${instance}" --force
        ;;
    esac

else
    if [ -z "${instance}" ]; then
        read -r instance <<<$(select_instance)
    fi

    if [ -z "${instance}" ]; then
        error "No instance selected"
    fi

    # determine the target type
    TARGET_TYPE="names"
    if [[ "${instance}" =~ $DOMAIN_REGEX ]]; then
        TARGET_TYPE="domains"
    fi

    INSTANCE=$(get_instance "$TARGET_TYPE" "$instance")

    # failsafe
    if [ ! -d "${INSTANCE}" ]; then
        error "The instance ${INSTANCE} does not exist"
    fi

    # get user selection if no action is provided
    if [ -z "${action}" ]; then
        read -r action <<<$(select_action "${INSTANCE}")
    fi

    if [ -z "${action}" ]; then
        error "No action selected for the instance $(basename "${INSTANCE}")"
    fi

    # add .sh if not present
    if [[ ! "${action}" == *.sh ]]; then
        action="${action}.sh"
    fi

    if [ ! -f "${INSTANCE}/${action}" ]; then
        echo -e "${COLOR_RED}The action $(mark "${action%.sh}")${COLOR_RED} does not exist for the instance $(mark "$(basename "${INSTANCE}")")"
        echo -e "Available actions: $(get_available_actions "${INSTANCE}")"
        exit 1
    fi

    bash "${INSTANCE}/${action}"

fi
