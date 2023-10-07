#!/bin/bash

# basic variables and functions for a easy-serve script
# can be used in scripts where user inputs or verification is needed

NOW=$(date "+%Y-%m-%d_%H-%M")
CURRENT_FOLDER=$(basename $(pwd))

TEMPLATES_DIR="/opt/easy-serve/templates"
INSTANCES_DIR="/opt/easy-serve-instances"

RESTORE_TEMP_DIR="/opt/easy-serve-tmp/restore/$NOW"
BACKUP_TEMP_DIR="/opt/easy-serve-tmp/backup/$NOW"

EACH_SCRIPTS_DIR="/opt/easy-serve/scripts/each"


# 0 = debug, 1 = info, 2 = warning, 3 = error
LOG_LEVEL=0

# Define ANSI escape codes for colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

write() {
    local level=$1
    local message=$2
    
    local prefix=""
    local color="$NC"
    case $level in
        2) # Warning
            prefix="Warning: "
            color="$YELLOW"
            ;;
        3) # Error
            color="$RED"
            ;;
    esac

    if [[ $level -ge $LOG_LEVEL ]]; then
        echo -e "${color}${prefix}${message}${NC}"
    fi
}

# Join two paths
join_paths() {  
    local IFS="/"
    echo "$*"
}

prompt_decision() {
    local message="$1"
    local choice

    while true; do
        read -p "$message (y/n): " choice
        case "$choice" in
            y|Y) 
                return 0  # Return with success exit code
                ;;
            n|N)
                return 1  # Return with failure exit code
                ;;
            *)
                echo "Invalid choice. Please select 'y' or 'n'."
                ;;
        esac
    done
}

