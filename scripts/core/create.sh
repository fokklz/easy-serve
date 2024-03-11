#!/bin/bash
# Path: scripts/core/manage.sh
# Author: Fokko Vos
#
# This script is meant to manage instances
# the necessary information is requested from the user interactively using fuzzy search
# for quick actions also supports direct action execution without interactive selection

# FLAGS
# --no-sftp

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"
source "${DIR}/../fuzzy.sh"

if [ ! -f "${INDEX_FILE}" ]; then
    echo '{"names": {}, "domains": {}}' >"$INDEX_FILE"
fi

named_args "template|lower" "domain|lower" "instance_name|lower"

VALID_TYPE=$(is_valid_type "${template}")
while [ "$VALID_TYPE" != 0 ]; do
    # TODO: use fzf instead to select a template template
    read -r template <<<$(select_template)
    VALID_TYPE=$(is_valid_type "${template}")
done

# if the provided domain is something and does not contain a dot, append the global domain
if [[ ! -z "${domain}" ]] && [[ "${domain}" != *.* ]]; then
    domain="${domain}.${DOMAIN}"
fi

VALID_DOMAIN=$(is_valid_domain "${domain}")
while [ "$VALID_DOMAIN" != 0 ]; do
    REASON="is not a valid domain"
    if [ "$VALID_DOMAIN" = 2 ]; then
        REASON="is already in use"
    fi

    ask_input "Domain ${domain:-???} ${REASON}. Please provide a different domain" "${DOMAIN_REGEX}" "" domain
    VALID_DOMAIN=$(is_valid_domain "${domain}")
done

NAME="${domain%%.*}"

if [ -n "$instance_name" ]; then
    NAME="${instance_name}"
fi

VALID_NAME=$(is_valid_name "${NAME}")
while [ "$VALID_NAME" != 0 ]; do
    REASON="is not a valid name"
    if [ "$VALID_NAME" = 2 ]; then
        REASON="is already in use"
    fi

    ask_input "Name ${NAME:-???} ${REASON}. Please provide a different name" "${NAME_REGEX}" "" NAME
    VALID_NAME=$(is_valid_name "${NAME}")
done

INSTANCE="${INSTANCE_ROOT}/${template}/${NAME}"
TEMPLATE="${TEMPLATE_ROOT}/${template}"

# finally re-esure the instance does not exist by full path
if [ -d "${INSTANCE}" ]; then
    error "Instance ${NAME} already exists"
fi

mkdir -p "$INSTANCE"
(
    for item in "${TEMPLATE}"/*; do
        if [[ "$(basename "$item")" != "install.sh" ]]; then
            cp -r "$item" "$INSTANCE/"
        fi
    done
) &
loading_spinner "Initializing ${template}..." "Template files Coppied to ${template}/${NAME}"

bash "${TEMPLATE}/install.sh" "${domain}" "${NAME}" "${INSTANCE}" >"${INSTANCE}/.env"

(
    cd "${INSTANCE}" || exit

    # -- start.sh --

    cat >"start.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/start.sh
# Author: auto-generated
#
# This script is used to start the ${NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE}
    docker compose up -d
) & loading_spinner "Starting \$(mark "$NAME")..." "Started \$(mark "$NAME") successfully."
EOF
    chmod +x start.sh

    # -- stop.sh --

    cat >"stop.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/stop.sh
# Author: auto-generated
#
# This script is used to stop the ${NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE}
    docker compose down
) & loading_spinner "Stopping \$(mark "$NAME")..." "Stopped \$(mark "$NAME") successfully."
EOF
    chmod +x stop.sh

    # -- restart.sh --

    cat >"restart.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/restart.sh
# Author: auto-generated
#
# This script is used to restart the ${NAME} instance

bash "${INSTANCE}/stop.sh"
bash "${INSTANCE}/start.sh"
EOF

    chmod +x restart.sh

    # -- uninstall.sh --

    cat >"uninstall.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/uninstall.sh
# Author: auto-generated
#
# This script is used to uninstall the ${NAME} instance

bash "${SCRIPTS_DIR}/instance/uninstall.sh" "${TYPE}" "${NAME}"
EOF

    chmod +x uninstall.sh

) &
loading_spinner "Creating instance scripts for $(mark "${NAME}")..." "Created instance scripts for $(mark "${NAME}")"

# store domain and name in the index file
jq --arg name "$NAME" --arg instance "$INSTANCE" --arg domain "$domain" '.names += {($name): $instance} | .domains += {($domain): $instance}' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

if [ "$NO_SFTP" != true ]; then
    bash "${DIR}/../sftp/add-user.sh" "${NAME}" "${INSTANCE}/webroot"
fi

bash "${INSTANCE}/start.sh"

echo -e "Serving $(mark "${NAME}") at $(mark "https://${domain}")"
