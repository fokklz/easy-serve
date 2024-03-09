#!/bin/bash
# Path: scripts/template/create-instance-scripts.sh
# Author: Fokko Vos

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

if [ $# -lt 2 ]; then
    error "Usage: $0 <type> <name>"
fi

TYPE=$(echo "${1}" | awk '{print tolower($0)}')
NAME=$(echo "${2}" | awk '{print tolower($0)}')

INSTANCE_ROOT="${INSTANCE_ROOT}/${TYPE}/${NAME}"
(
    cd "${INSTANCE_ROOT}" || exit

    # -- start.sh --

    cat >"start.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE_ROOT}/start.sh
# Author: auto-generated
#
# This script is used to start the ${NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE_ROOT}
    docker compose up -d > /dev/null 2>&1
) & loading_spinner "Starting \$(mark "$NAME")..." "Started \$(mark "$NAME") successfully."
EOF
    chmod +x start.sh

    # -- stop.sh --

    cat >"stop.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE_ROOT}/stop.sh
# Author: auto-generated
#
# This script is used to stop the ${NAME} instance

source "${SCRIPTS_DIR}/globals.sh"

(
    cd ${INSTANCE_ROOT}
    docker compose down > /dev/null 2>&1
) & loading_spinner "Stopping \$(mark "$NAME")..." "Stopped \$(mark "$NAME") successfully."
EOF
    chmod +x stop.sh

    # -- restart.sh --

    cat >"restart.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE_ROOT}/restart.sh
# Author: auto-generated
#
# This script is used to restart the ${NAME} instance

bash "${INSTANCE_ROOT}/stop.sh"
bash "${INSTANCE_ROOT}/start.sh"
EOF

    chmod +x restart.sh

    # -- uninstall.sh --

    cat >"uninstall.sh" <<EOF
#!/bin/bash
# Path: ${INSTANCE_ROOT}/uninstall.sh
# Author: auto-generated
#
# This script is used to uninstall the ${NAME} instance

bash "${SCRIPTS_DIR}/instance/uninstall.sh" "${TYPE}" "${NAME}"
EOF

    chmod +x uninstall.sh

) &
loading_spinner "Creating instance scripts for $(mark "${NAME}")..." "Created instance scripts for $(mark "${NAME}")"
