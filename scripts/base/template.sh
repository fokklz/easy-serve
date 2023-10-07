#!/bin/bash

source /opt/easy-serve/scripts/base/script.sh

# Extract all existing instance names from the instances directory
# Will help to check if a name is already in use and prevent duplicates
INSTANCE_NAMES=()
if [[ -d "$INSTANCES_DIR" ]]; then
    for template in $(ls "$INSTANCES_DIR"); do
        INSTANCE_NAMES+=($(ls "$INSTANCES_DIR/$template"))
    done
fi

# Extract all used domains from traefik to prevent duplicates
DOMAINS=()
if [[ ping -c 4 "https://traefik.fokklz.dev" ]]; then
    DOMAINS=$(echo "$(curl -s -u test:test https://traefik.fokklz.dev/api/rawdata)" | jq -r '.routers | .[] | select(.rule | startswith("Host")) | .rule' | sed -E 's/Host\(`(.*)`\)/\1/')
fi

# Initialite a new instance of a template
# Usage: init <template> <name>
# WILL CHANGE TO THE NEW INSTANCE DIRECTORY
init() {
    local template=$1
    local name=$2
    
    
    local source_dir="$TEMPLATES_DIR/$template"
    local target_dir="$INSTANCES_DIR/$template/$name"
    
    mkdir -p "$target_dir"

    # Copy all files and directories except install.sh
    for item in "${source_dir}"/*; do
        if [[ "$(basename "$item")" != "install.sh" ]]; then
            cp -r "$item" "$target_dir/"
        fi
    done

    write 1 "Template $template has been created under "
    write 1 "   $template/$name"
    cd "$target_dir"
}


# Write the environment variables to the .env file for a template
# Should be used by the install script for a template to create all needed environment variables
# These will be used by the docker-compose file, some will only apply on first start.
# TODO: Implement function for reset without loss of data
# Usage: write_env <line1> <line2> ...
# WILL CREATE THE .env FILE IN THE CURRENT DIRECTORY
write_env() {
    local target_dir="$(pwd)"
    
    # Check if target directory exists
    if [[ ! -d $target_dir ]]; then
        write 3 "Target directory $target_dir does not exist"
        write 0 "You should use write_env only after init was called"
        exit 1
    fi

    # Create or overwrite the .env file
    > "${target_dir}/.env"
    
    # Append each argument as a new line to the .env file
    for line in "$@"; do
        echo "$line" >> "${target_dir}/.env"
    done

    # Copy all scripts from the each directory to the target directory
    # TODO: Create a function to only copy scripts for repair
    for script in $(ls "$EACH_SCRIPTS_DIR"); do
        ln -s "$EACH_SCRIPTS_DIR/$script" "$target_dir"
    done
    
    write 1 "Environment has been written & scripts coppied"
}


# Generate a random password of a given length
# Usage: generate_password [length]
generate_password(){
    local length=${1:-10}
    local password=$(openssl rand -hex $length)
    echo "$password"
}

# Check if a domain is already in use
# Usage: check_domain_usage <domain>
check_domain_usage() {
    local domain_to_check=$1

    for domain in $DOMAINS; do
        if [[ "$domain" == "$domain_to_check" ]]; then
            write 3 "The domain $domain_to_check is already in use. Please choose another domain."
            return 1
        fi
    done
    return 0
}

# Prompt the user for domain input
# Usage: input_domain
# Should be used as right hand arguemnt for DOMAIN="$(input_domain)"
input_domain(){
    while true; do
        # Prompt the user for domain input
        read -p "Enter a domain: " input_domain

        if check_domain_usage "$input_domain"; then
            write 3 "The domain $input_domain is already in use. Please choose another domain."
            continue
        fi

        echo "$input_domain"
        break
    done
}

# Prompt the user for name input
# Usage: input_name [default]
# Should be used as right hand arguemnt for NAME="$(input_name)"
input_name(){
    local default=""
    local default_value=""
    if [[ -n "$1" ]]; then
        # Replace all dots with hyphens
        default_value=${1//./-}
        # Remove the part after the last hyphen
        default_value=${default_value%-*}
        default="(default: $default_value)"
    fi

    while true; do
        # Prompt the user for name input
        read -p "Enter a name $default: " input_name
        name=${input_name:-$default_value}

        # I think this is not a clean approach, but it works and i don't know a better one
        for existing in $INSTANCE_NAMES; do
            if [[ "$existing" == "$name" ]]; then
                write 3 "The name $name is already in use. Please choose another name."
                continue
            fi
        done

        echo "$name"
        break
    done
}