#!/bin/bash

source /opt/easy-serve/scripts/base/template.sh

# Terminate the script if any error occurs
abort_restore() {
    write 3 "Aborting restore."
    rm -rf $RESTORE_TEMP_DIR
    exit 1
}

# Ensure the user has provided a path to the backup file
if [ "$#" -ne 1 ]; then
    write 3 "Usage: $0 <path_to_backup_tar.gz>"
    exit 1
fi

BACKUP_PATH="$1"
# Validate if the backup path exists
if [ ! -f "$BACKUP_PATH" ]; then
    write 3 "Specified backup path does not exist."
    exit 1
fi
# Validate if the backup path is a tar.gz file
if [[ "$BACKUP_PATH" != *.tar.gz ]]; then
    write 3 "The specified file is not a tar.gz archive."
    exit 1
fi

# Create temporary restore folder
mkdir -p $RESTORE_TEMP_DIR
# Extract the backup file
tar -xzvf $BACKUP_PATH -C $RESTORE_TEMP_DIR

# Ensure the backup is valid
if [[ ! -f "$RESTORE_TEMP_DIR/.env" ]]; then
    write 3 "The backup does not contain a Environment file."
    abort_restore
else
    source $RESTORE_TEMP_DIR/.env
fi

# Ensure the domain will be available, allow for change if not
# TODO: More options like only parse volumes instead of aborting
if [[ -n "$DOMAIN" && "$(check_domain_usage "$DOMAIN")" ]]; then
    write 3 "The domain $DOMAIN is already in use."
    if prompt_decision "Do you want to set a other domain?"; then
        DOMAIN="$(input_domain)"
    else
        abort_restore
    fi
fi


