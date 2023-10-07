#!/bin/bash

(
    source /opt/easy-serve/scripts/base/script.sh

    SCRIPT_DIR="$(dirname "$0")"

    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
        write 3 "Environment file not found."
        exit 1
    fi
    source $SCRIPT_DIR/.env

    # basic script to backup a compose project with all its volumes included
    VOLUMES=$(yq e '.volumes | keys' $SCRIPT_DIR/docker-compose.yml | awk -F' ' '{print $2}')

    # Ensure relevant folders exist
    mkdir -p backups
    mkdir -p $BACKUP_TEMP_DIR

    # copy all relevant files to the backup folder
    find $SCRIPT_DIR -maxdepth 1 ! -name '.' ! -name 'backups' ! -name '*.sh' -exec cp -a {} "$BACKUP_TEMP_DIR" \;

    write 1 "Creating backup of ${NAME//$'\r'/} to $BACKUP_TEMP_DIR"
    # Loop through the volumes & create a snapshot
    for volume in $VOLUMES; do
        full_volume_name="${NAME}_${volume}"
        custom_name=$(yq e ".volumes.${volume}.name" docker-compose.yml)
        if [[ "$custom_name" != "null" && ! -z "$custom_name" ]]; then
            # If the "name" attribute exists, use it
            full_volume_name=$custom_name
        fi
        echo "Creating snapshot of $full_volume_name"
        docker run --rm -v $full_volume_name:/volume/$volume -v $BACKUP_TEMP_DIR/volumes:/backup alpine cp -a /volume/$volume/. /backup/$volume
    done

    docker run --rm -v $BACKUP_TEMP_DIR:/backup -v $SCRIPT_DIR/backups:/out alpine sh -c "apk add --no-cache tar && tar -czvf /out/$NOW.tar.gz -C /backup ."
    rm -rf $BACKUP_TEMP_DIR
)