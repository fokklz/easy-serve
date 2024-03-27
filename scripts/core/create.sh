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

NO_PROMPT_TEMPLATE=true

register_arg "template" "" "${FOLDER_REGEX}"
register_arg "domain" "" "${FOLDER_REGEX}|${DOMAIN_REGEX}"
register_arg "name" "\${ARG_DOMAIN%%.*}" "${FOLDER_REGEX}"

if [ ! -f "${INDEX_FILE}" ]; then
    echo '{"names": {}, "domains": {}, "users": {}}' >"$INDEX_FILE"
fi

source "${SCRIPTS_DIR}/args.sh"

source "${SCRIPTS_DIR}/utils/fuzzy.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

VALID_TYPE=$(is_valid_template "${ARG_TEMPLATE}")
while [ "$VALID_TYPE" != 0 ]; do
    # TODO: use fzf instead to select a template template
    read -r ARG_TEMPLATE <<<$(select_template)
    VALID_TYPE=$(is_valid_template "${ARG_TEMPLATE}")
done

# if the provided ARG_DOMAIN is something and does not contain a dot, append the global ARG_DOMAIN
if [[ ! -z "${ARG_DOMAIN}" ]] && [[ "${ARG_DOMAIN}" != *.* ]]; then
    ARG_DOMAIN="${ARG_DOMAIN}.${DOMAIN}"
fi

if [ -z "${ARG_NAME}" ]; then
    ARG_NAME="${ARG_DOMAIN%%.*}"
fi

INSTANCE="${INSTANCE_ROOT}/${ARG_TEMPLATE}/${ARG_NAME}"
TEMPLATE="${TEMPLATE_ROOT}/${ARG_TEMPLATE}"

# finally re-esure the instance does not exist by full path
if [ -d "${INSTANCE}" ]; then
    error "Instance ${ARG_NAME} already exists"
fi

mkdir -p "$INSTANCE"
(
    for item in "${TEMPLATE}"/*; do
        if [[ "$(basename "$item")" != "install.sh" ]]; then
            cp -r "$item" "$INSTANCE/"
        fi
    done
) &
loading_spinner "Initializing ${TEMPLATE}..." "Template files Coppied to ${TEMPLATE}/${ARG_NAME}"

bash "${TEMPLATE}/install.sh" "${ARG_DOMAIN}" "${ARG_NAME}" "${DOCKER_NETWORK}" >"${INSTANCE}/.env"

(
    cd "${INSTANCE}" || exit

    # -- start.sh --

    cat >"start.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/start.sh
# Author: auto-generated
#
# This script is used to start the ${ARG_NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE}
    docker compose up -d
) & loading_spinner "Starting \$(mark "$ARG_NAME")..." "Started \$(mark "$ARG_NAME") successfully."
EOF
    chmod +x start.sh

    # -- stop.sh --

    cat >"stop.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/stop.sh
# Author: auto-generated
#
# This script is used to stop the ${ARG_NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE}
    docker compose down
) & loading_spinner "Stopping \$(mark "$ARG_NAME")..." "Stopped \$(mark "$ARG_NAME") successfully."
EOF
    chmod +x stop.sh

    # -- restart.sh --

    cat >"restart.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/restart.sh
# Author: auto-generated
#
# This script is used to restart the ${ARG_NAME} instance

bash "${INSTANCE}/stop.sh"
bash "${INSTANCE}/start.sh"
EOF

    chmod +x restart.sh

    # -- *.sh from instance --

    for item in "${SCRIPTS_DIR}/instance/"*; do
        name=$(basename "$item")

        cat >"$name" <<EOF
#!/bin/bash
# Path: ${INSTANCE}/${name}
# Author: auto-generated
#
# This script is used to ${name%.*} the ${ARG_NAME} instance

bash "${SCRIPTS_DIR}/instance/${name}" "${ARG_NAME}"
EOF

        chmod +x "$name"
    done

) &
loading_spinner "Creating instance scripts for $(mark "${ARG_NAME}")..." "Created instance scripts for $(mark "${ARG_NAME}")"

# store ARG_DOMAIN and name in the index file
jq --arg name "$ARG_NAME" --arg instance "$INSTANCE" --arg domain "$ARG_DOMAIN" '.names += {($name): $instance} | .domains += {($domain): $instance}' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

if [ "$NO_SFTP" != true ]; then
    bash "${DIR}/../sftp/add-user.sh" "${ARG_NAME}" "${INSTANCE}"
fi

bash "${INSTANCE}/start.sh"

echo -e "Serving $(mark "${ARG_NAME}") at $(mark "https://${ARG_DOMAIN}")"

if [ "$NO_SFTP" != true ]; then
    # check if $ARG_FOLDER includes wordpress (case insensitive)
    if [[ "${INSTANCE,,}" == *"wordpress"* ]]; then
        # WordPress-specific adjustments
        find "${INSTANCE}/webroot" -type f -exec chmod 644 {} \;
        find "${INSTANCE}/webroot" -type d -exec chmod 755 {} \;

        # Special handling for wp-config.php
        chmod 600 "${INSTANCE}/webroot/wp-config.php" >/dev/null 2>&1

        # Specific permissions for uploads directory
        chmod -R 755 "${INSTANCE}/webroot/wp-content/uploads" >/dev/null 2>&1
    fi
fi
