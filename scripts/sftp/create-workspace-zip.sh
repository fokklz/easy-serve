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

register_arg "user" "" "${FOLDER_REGEX}"
register_arg "out"

source "${SCRIPTS_DIR}/args.sh"

# ----------------------------------------------- \\
# Start of the script
# ----------------------------------------------- \\

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
    cp "${SFTP_KEYS_DIR}/${ARG_USER}_id_ed25519_key" "./.vscode/${ARG_USER}_id_ed25519_key"

    # -- .vscode/extensions.json --

    cat >".vscode/extensions.json" <<EOF
{
  "recommendations": ["natizyskunk.sftp"]
}
EOF

    # -- .vscode/sftp.json --

    cat >".vscode/sftp.json" <<EOF
{
  "name": "${ARG_USER} - ${DOMAIN}",
  "host": "sftp.${DOMAIN}",
  "protocol": "sftp",
  "port": ${SFTP_PORT:-22},
  "username": "${ARG_USER}",
  "privateKeyPath": ".vscode/${ARG_USER}_id_ed25519_key",
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
      ".vscode/${ARG_USER}_id_ed25519_key"
  ]
}
EOF

    if [ -f "${ARG_OUT}/workspace.zip" ]; then
        rm -f "${ARG_OUT}/workspace.zip"
    fi

    # ZIP the created workspace and move it to the output directory
    zip -r -q "workspace.zip" .
    mv "workspace.zip" "${ARG_OUT}/workspace.zip"
) &
loading_spinner "Creating workspace for $(mark "$ARG_USER")..." \
    "Created workspace for $(mark "$ARG_USER")"

# cleanup
rm -rf "${TEMP_DIR}"
