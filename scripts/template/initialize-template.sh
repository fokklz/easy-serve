# FLAGS
# --no-sftp

DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

named_args "TYPE|lower" "TEMPLATE_DOMAIN|lower" "localname|lower"

echo "Initializing ${TYPE} instance with domain ${TEMPLATE_DOMAIN}"

# if the provided domain does not contain a dot, append the global domain
if [[ "${TEMPLATE_DOMAIN}" != *.* ]]; then
    TEMPLATE_DOMAIN="${TEMPLATE_DOMAIN}.${DOMAIN}"
fi
NAME="${TEMPLATE_DOMAIN%%.*}"

if [ -n "$localname" ]; then
    NAME="${localname}"
fi

INSTANCE="${INSTANCE_ROOT}/${TYPE}/${NAME}"
TEMPLATE="${TEMPLATE_ROOT}/${TYPE}"

if [ -d "${INSTANCE}" ]; then
    error "Instance ${NAME} for ${TYPE} already exists"
fi

DOMAINS=()
if ping -c 4 "traefik.${DOMAIN}" &>/dev/null; then
    DOMAINS=$(echo "$(curl -sS --cert-type P12 --cert $(cat ${SEC_CERT}) "https://traefik.${DOMAIN}/api/rawdata")" | jq -r '.routers | .[] | select(.rule | startswith("Host")) | .rule' | sed -E 's/Host\(`(.*)`\)/\1/')
fi

if [[ " ${DOMAINS[@]} " =~ " ${TEMPLATE_DOMAIN} " ]]; then
    error "Domain ${TEMPLATE_DOMAIN} already in use"
fi

mkdir -p "$INSTANCE"
(
    for item in "${TEMPLATE}"/*; do
        if [[ "$(basename "$item")" != "install.sh" ]]; then
            cp -r "$item" "$INSTANCE/"
        fi
    done
) &
loading_spinner "Initializing ${TYPE}..." "Template files Coppied to ${TYPE}/${NAME}"

bash "${TEMPLATE}/install.sh" "${TEMPLATE_DOMAIN}" "${NAME}" "${INSTANCE}" >"${INSTANCE}/.env"
bash "${DIR}/create-basic-scripts.sh" "${TYPE}" "${NAME}"

if [ "$NO_SFTP" != true ]; then
    bash "${DIR}/../sftp/add-user.sh" "${NAME}" "${INSTANCE}/webroot"
fi

bash "${INSTANCE}/start.sh"

echo -e "Serving $(mark "${NAME}") at $(mark "https://${TEMPLATE_DOMAIN}")"
