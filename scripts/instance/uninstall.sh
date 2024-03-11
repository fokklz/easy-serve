DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

named_args "name"

TARGET_TYPE="names"
if [[ "${name}" =~ $DOMAIN_REGEX ]]; then
    TARGET_TYPE="domains"
fi

INSTANCE=$(get_instance "${TARGET_TYPE}" "${name}")

source "${INSTANCE}/.env"

echo "Uninstalling the instance ${INSTANCE_NAME} served at ${INSTANCE_DOMAIN}..."
echo "${@} value of force is ${FORCE}"

if prompt_confirmation "Are you sure you want to uninstall the instance ${INSTANCE_NAME} served at ${INSTANCE_DOMAIN}?"; then
    bash "${INSTANCE}/stop.sh"
    bash "${DIR}/../sftp/remove-user.sh" "${INSTANCE_NAME}" --soft
    rm -rf "${INSTANCE}"
else
    echo "Aborted."
fi
