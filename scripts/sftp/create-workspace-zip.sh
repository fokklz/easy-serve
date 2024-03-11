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

named_args "USER|lower" "OUT"

# ensure workspace exists
WORKSPACE="${TEMP_DIR}/workspace"
if [ ! -d "${WORKSPACE}" ]; then
    mkdir -p "${WORKSPACE}"
fi

(
    cd "${WORKSPACE}"
    if [ ! -d ".vscode" ]; then
        mkdir -p ".vscode"
    fi

    # include the user's private key in the workspace
    cp "${SFTP_KEYS_DIR}/${USER}_id_ed25519_key" "./.vscode/${USER}_id_ed25519_key"

    # -- .vscode/extensions.json --

    cat >".vscode/extensions.json" <<EOF
{
  "recommendations": ["natizyskunk.sftp"]
}
EOF

    # -- .vscode/sftp.json --

    cat >".vscode/sftp.json" <<EOF
{
  "name": "${USER} - ${DOMAIN}",
  "host": "sftp.${DOMAIN}",
  "protocol": "sftp",
  "port": ${SFTP_PORT:-22},
  "username": "${USER}",
  "privateKeyPath": ".vscode/${USER}_id_ed25519_key",
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
      ".vscode/extensions.json",
      ".vscode/${USER}_id_ed25519_key"
  ]
}
EOF

    if [ -f "${OUT}/workspace.zip" ]; then
        rm -f "${OUT}/workspace.zip"
    fi

    # ZIP the created workspace and move it to the output directory
    zip -r -q "workspace.zip" .
    mv "workspace.zip" "${OUT}/workspace.zip"
) &
loading_spinner "Creating workspace for $(mark "$USER")..." \
    "Created workspace for $(mark "$USER")"

# cleanup
rm -rf "${TEMP_DIR}"
