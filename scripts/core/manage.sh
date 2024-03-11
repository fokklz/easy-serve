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

if [ -z "${instance}" ]; then
    read -r instance <<<$(select_instance)
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
    sel_action:
    read -r action <<<$(select_action "${INSTANCE}")
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
