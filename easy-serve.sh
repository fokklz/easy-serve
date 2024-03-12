#!/bin/bash

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/scripts/globals.sh"

named_args "command"

if [[ $FLAG_VERSION = true ]]; then
    print_version
    exit 0
fi

if [[ -z $command ]] || [[ $FLAG_HELP = true ]]; then
    print_help "$command"
    exit 0
fi

# Re-create the client certificate if it is older than 24 hours
if [[ -f "${SEC_CERT}" ]]; then
    last_modified=$(stat -c %Y "${SEC_CERT}")
    current_time=$(date +%s)
    time_diff=$((current_time - last_modified))
    if [[ $time_diff -gt 86400 ]]; then
        bash "${SCRIPTS_DIR}/security/rotate-client-cert.sh"
    fi
fi

case $command in
help)
    print_help
    ;;
manage)
    bash "${SCRIPTS_DIR}/core/manage.sh" ${@:2}
    ;;
create)
    bash "${SCRIPTS_DIR}/core/create.sh" ${@:2}
    ;;
create-client)
    bash "${SCRIPTS_DIR}/security/client-cert.sh" ${@:2}
    ;;
panic)
    bash "${SCRIPTS_DIR}/security/panic.sh" ${@:2}
    ;;
reset)
    bash "${SCRIPTS_DIR}/core/full-reset.sh" ${@:2}
    ;;
*)
    # ensure the command esists
    cmd=$(read_config ".commands[] | select(.name == \"$command\")")

    # print the help page again if the command does not exist
    if [[ -z $cmd ]]; then
        print_help
        exit 0
    fi

    bash "${SCRIPTS_DIR}/core/action.sh" "$command" ${@:2}
    ;;
esac
