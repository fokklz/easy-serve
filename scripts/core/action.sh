#!/bin/bash
# Path: scripts/core/action.sh
# Author: Fokko Vos
#
# This script is meant to manage instances by action
# the necessary information is requested from the user interactively using fuzzy search
# for quick actions also supports direct action execution without interactive selection
# pre-select the action to execute so you can only select on which instance to execute the action
#

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${DIR}/../fuzzy.sh"

named_args "action" "instance"

# add .sh if not present
if [[ ! "${action}" == *.sh ]]; then
    action="${action}.sh"
fi

if [ -z "${instance}" ]; then
    readarray -t instances < <(select_instance_with_action "${action}")
else
    instances=($instance) # Make sure instances is always an array
fi

for name in "${instances[@]}"; do
    if [ -z "${name}" ]; then
        continue
    fi

    # Determine the target type
    TARGET_TYPE="names"
    if [[ "${name}" =~ $DOMAIN_REGEX ]]; then
        TARGET_TYPE="domains"
    fi

    INSTANCE=$(get_instance "$TARGET_TYPE" "$name")

    # Failsafe
    if [ ! -d "${INSTANCE}" ]; then
        error "The instance ${INSTANCE} does not exist"
        continue
    fi

    # Pretty print the possible actions if invalid action is provided
    if [ ! -f "${INSTANCE}/${action}" ]; then
        echo -e "${COLOR_RED}The action $(mark "${action%.sh}")${COLOR_RED} does not exist for the instance $(mark "$(basename "${INSTANCE}")")"
        echo -e "Available actions: $(get_available_actions "${INSTANCE}")"
        continue
    fi

    bash "${INSTANCE}/${action}" $@
done
