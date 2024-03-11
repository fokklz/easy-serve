#!/bin/bash

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/scripts/globals.sh"

named_args "command"

if [[ -z $command ]]; then
    print_help
    exit 0
fi

case $command in
help)
    print_help
    ;;
manage)
    if [ "${HELP}" = true ]; then
        print_help "$command"
        exit 0
    fi

    bash "${SCRIPTS_DIR}/core/manage.sh" ${@:2}
    ;;
create)
    if [ "${HELP}" = true ]; then
        print_help "$command"
        exit 0
    fi

    bash "${SCRIPTS_DIR}/core/create.sh" ${@:2}
    ;;
*)
    # ensure the command esists
    cmd=$(read_config ".commands[] | select(.name == \"$command\")")

    # print the help page again if the command does not exist
    if [[ -z $cmd ]]; then
        print_help
        exit 0
    elif [ "${HELP}" = true ]; then
        print_help "$command"
        exit 0
    fi

    bash "${SCRIPTS_DIR}/core/action.sh" "$command" ${@:2}
    ;;
esac
