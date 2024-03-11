select_instance() {
    local slash_count=$(echo "$INSTANCE_ROOT" | awk -F/ '{print NF-1}')
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
        awk -F/ '{print $NF}'             # Output the instance type and name
}

select_template() {
    local slash_count=$(echo "$TEMPLATE_ROOT" | awk -F/ '{print NF-1}')
    slash_count=$((slash_count + 2))
    find "$TEMPLATE_ROOT" -mindepth 1 -maxdepth 1 -type d |
        fzf --height 10 --prompt "Select a template: " \
            --delimiter '/' \
            --with-nth "$slash_count.." | # Shows only the instance names
        awk -F/ '{print $NF}'             # Output the instance type and name
}

select_instance_with_action() {
    local action=$1

    local slash_count=$(echo "$INSTANCE_ROOT" | awk -F/ '{print NF-1}')
    slash_count=$((slash_count + 3))

    local instances=$(find "$INSTANCE_ROOT" -mindepth 2 -maxdepth 2 -type d -exec test -e "{}/${action}" \; -print)

    printf '%s\n' "${instances}" |
        fzf --prompt "Select an instance: " \
            --preview 'type="$(basename $(dirname {}))"; echo "Type: $type"; 
                       instance_name=$(grep -m 1 "^INSTANCE_NAME=" {}/.env | cut -d'=' -f2); 
                       instance_type=$(grep -m 1 "^INSTANCE_DOMAIN=" {}/.env | cut -d'=' -f2); 
                       echo "Name: ${instance_name//\"/}"; 
                       echo "Domain: ${instance_type//\"/}"' \
            --preview-window right:20%:bottom:wrap \
            --delimiter '/' \
            --with-nth "$slash_count.." --multi |
        awk -F/ '{print $NF}'
}

select_action() {
    local instance=$1
    local instance_name=$(basename "$instance")

    actions=($(find "${instance}" -type f -name "*.sh" -exec basename {} \;))

    printf '%s\n' "${actions[@]}" | fzf --height 10 --prompt "Select an action for $instance_name: "
}
