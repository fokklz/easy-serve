#!/bin/bash

source /opt/easy-serve/scripts/base/template.sh

TEMPLATE="wordpress-standalone"
DOMAIN="$(input_domain)"
NAME="$(input_name $DOMAIN)"

init "$TEMPLATE" "$NAME"

write_env "TEMPLATE=$TEMPLATE" \
    "NAME=$NAME" \
    "DOMAIN=$DOMAIN" \
    "MYSQL_ROOT_PASSWORD=$(generate_password)" \
    "MYSQL_PASSWORD=$(generate_password)"

# Starup sequence

docker compose up -d