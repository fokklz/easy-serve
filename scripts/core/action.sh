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

NO_PROMPT_NAME=true

register_arg "action" "" "${FOLDER_REGEX}"
register_arg "name" "" "${FOLDER_REGEX}"

EXPANSION=${@:3}

source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

# add .sh if not present
if [[ ! "${ARG_ACTION}" == *.sh ]]; then
    ARG_ACTION="${ARG_ACTION}.sh"
fi

if [ -z "${ARG_NAME}" ]; then
    # Select an instance
    readarray -t instances < <(select_instance_with_action "${ARG_ACTION}")
elif [[ "${ARG_NAME}" == *","* ]]; then
    # Support for comma separated values
    IFS=',' read -ra instances <<<"$ARG_NAME"
else
    # Single instance
    instances=($ARG_NAME) # Make sure instances is always an array
fi

for name in "${instances[@]}"; do
    if [ -z "${name}" ]; then
        # Skip empty values
        continue
    fi

    # Determine the target type
    TARGET_TYPE="names"
    if [[ "${name}" =~ $DOMAIN_REGEX ]]; then
        TARGET_TYPE="domains"
    fi

    # Get the instance path by type and name
    INSTANCE=$(get_instance "$TARGET_TYPE" "$name")

    # Failsafe
    if [ ! -d "${INSTANCE}" ]; then
        warning "The instance ${INSTANCE} does not exist"
        continue
    fi

    # Pretty print the possible actions if invalid action is provided
    if [ ! -f "${INSTANCE}/${ARG_ACTION}" ]; then
        warning "The action $(mark "${ARG_ACTION%.sh}")${COLOR_YELLOW} does not exist for the instance $(mark "$(basename "${INSTANCE}")")"
        warning "Available actions: $(get_available_actions "${INSTANCE}")"
        continue
    fi

    bash "${INSTANCE}/${ARG_ACTION}" $EXPANSION
done
