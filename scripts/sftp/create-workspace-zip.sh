#!/bin/bash
# Path: scripts/sftp/create-workspace-zip.sh
# Author: Fokko Vos
#
# Creates a workspace zip file for a user to use with vscode sftp extension
# simplifies the process of setting up a workspace for a user
# all needed information is stored in the zip file

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

TEMP_DIR=$(mktemp -d)

source "${DIR}/../globals.sh"

if [ $# -lt 2 ]; then
    error "Usage: $0 <username> <password>"
fi

USER=$(echo "${1}" | awk '{print tolower($0)}')
PASSWORD=$2

WORKSPACE="${TEMP_DIR}/workspace"
if [ ! -d "${WORKSPACE}" ]; then
    mkdir -p "${WORKSPACE}"
fi
(
    cd "${WORKSPACE}"
    if [ ! -d ".vscode" ]; then
        mkdir -p ".vscode"
    fi

    cat >".vscode/extensions.json" <<EOF
{
  "recommendations": ["natizyskunk.sftp"]
}
EOF

    cat >".vscode/sftp.json" <<EOF
{
  "name": "${USER} - ${DOMAIN}",
  "host": "sftp.${DOMAIN}",
  "protocol": "sftp",
  "port": ${SFTP_PORT:-22},
  "username": "${USER}",
  "password": "${PASSWORD}",
  "remotePath": "webroot",
  "uploadOnSave": true,
  "downloadOnOpen": true,
  "watcher": {
      "files": "*",
      "autoUpload": true,
      "autoDelete": true
  },
  "ignore": [
      ".vscode/sftp.json",
      ".vscode/extensions.json"
  ]
}
EOF

    if [ -f "${OUT}/workspace.zip" ]; then
        rm -f "${OUT}/workspace.zip"
    fi

    zip -r -q "workspace.zip" .
    mv "workspace.zip" "${OUT}/workspace.zip"
) &
loading_spinner "Creating workspace for $(mark "$USER")..." \
    "Created workspace for $(mark "$USER")"

rm -rf "${TEMP_DIR}"
