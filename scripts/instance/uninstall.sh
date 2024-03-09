DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

named_args "TYPE|lower" "NAME|lower"

INSTANCE="${INSTANCE_ROOT}/${TYPE}/${NAME}"

source "${INSTANCE}/.env"

if prompt_confirmation "Are you sure you want to uninstall the instance ${INSTANCE_NAME} served at ${INSTANCE_DOMAIN}?"; then
    bash "${INSTANCE}/stop.sh"
    bash "${DIR}/../sftp/remove-user.sh" "${INSTANCE_NAME}" --soft
    rm -rf "${INSTANCE}"
else
    echo "Aborted."
fi
