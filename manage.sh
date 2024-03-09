#!/bin/bash

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/scripts/globals.sh"

# Function to display instances and capture the selected one
select_instance() {
    slash_count=$(echo "$INSTANCE_ROOT" | awk -F/ '{print NF-1}')
    slash_count=$((slash_count + 3))
    find "$INSTANCE_ROOT" -mindepth 2 -maxdepth 2 -type d |
        fzf --prompt "Select an instance: " \
            --preview 'type="$(basename $(dirname {}))"; echo "Type: $type"; 
                       instance_name=$(grep -m 1 "^INSTANCE_NAME=" {}/.env | cut -d'=' -f2); 
                       instance_type=$(grep -m 1 "^INSTANCE_DOMAIN=" {}/.env | cut -d'=' -f2); 
                       echo "Name: ${instance_name//\"/}"; 
                       echo "Domain: ${instance_type//\"/}"' \
            --preview-window right:20%:bottom:wrap \
            --delimiter '/' \
            --with-nth "$slash_count.." | # Shows only the instance names
        awk -F/ '{print $(NF-1) "/" $NF}' # Output the instance type and name
}

select_template() {
    slash_count=$(echo "$TEMPLATE_ROOT" | awk -F/ '{print NF-1}')
    slash_count=$((slash_count + 2))
    find "$TEMPLATE_ROOT" -mindepth 1 -maxdepth 1 -type d |
        fzf --height 10 --prompt "Select a template: " \
            --delimiter '/' \
            --with-nth "$slash_count.." | # Shows only the instance names
        awk -F/ '{print $NF}'             # Output the instance type and name
}

# Function to perform an action on an instance
select_and_perform_action() {
    local instance=$1
    local type=$2
    local script_path="${INSTANCE_ROOT}/${type}/${instance}/${action}"

    actions=($(find "${INSTANCE_ROOT}/${type}/${instance}" -type f -name "*.sh" -exec basename {} \;))
    action=$(printf '%s\n' "${actions[@]}" | fzf --height 10 --prompt "Select an action for $instance: ")

    if [ -z "$action" ]; then
        error "No action selected. Exiting."
    fi

    bash "$script_path/$action"
}

if [[ "${HELP:-false}" == true ]]; then
    echo -e "Usage: \n manage.sh - performe a action on a instance\n manage.sh create - create a new instance\n manage.sh <instance> <type> - performe a action on a instance"
    exit 0
fi

if [ $# -lt 1 ]; then
    # Select the instance and type
    IFS='/' read -r type instance <<<$(select_instance)

    if [ -z "$instance" ] || [ -z "$type" ]; then
        error "Instance selection canceled. Exiting."
    fi

    if [ ! -d "${INSTANCE_ROOT}/${type}/${instance}" ]; then
        error "Instance ${instance} for ${type} does not exist"
    fi

    # Perform the action
    select_and_perform_action "$instance" "$type"
elif [ $# -eq 1 ]; then
    action=$1

    case $action in
    create)
        read -r template <<<$(select_template)

        if [ -z "$template" ]; then
            error "Template selection canceled. Exiting."
        fi

        bash "${SCRIPTS_DIR}/template/initialize-template.sh" "${template}"
        ;;
    esac
else
    instance=$1
    type=$2

    select_and_perform_action "$instance" "$type"
fi
