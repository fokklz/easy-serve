DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

bash "${DIR}/utils/third-party.sh"

source "${DIR}/globals.sh"

hostnames=($(hostname -I))

if [ -f "${DIR}/../.env" ]; then
    rm -f "${ROOT}/install.sh" >/dev/null 2>&1
    error "Seems to be already installed. Exiting."
fi

register_arg "http" "${hostnames[0]}" "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" "Please enter the IP address for the HTTP server"
register_arg "sftp" "\${ARG_HTTP}" "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" "Please enter the IP address for the SFTP server"
register_arg "sftp_port" "2233" "^[0-9]+$" "Please enter the port for the SFTP server. Recommended to change"
register_arg "core_domain" "" "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Please enter the domain"
register_arg "acme_email" "admin@\${ARG_CORE_DOMAIN}" "^.*@.*\..*$" "Please enter the email for the ACME certificate"
register_arg "network" "traefik_network" "^[A-Za-z0-9_]+$" "Please enter the name for the docker network"

source "${SCRIPTS_DIR}/args.sh"

if ! docker network inspect "$ARG_NETWORK" >/dev/null 2>&1; then
    docker network create "$ARG_NETWORK"
fi

cat >"${ROOT}/.env" <<EOF
HTTP_IP_ADDRESS="${ARG_HTTP}"
SFTP_IP_ADDRESS="${ARG_SFTP}"

HTTP_PORT="80"
HTTPS_PORT="443"
SFTP_PORT="${ARG_SFTP_PORT}"

DOMAIN="${ARG_CORE_DOMAIN}"
ACME_EMAIL="${ARG_ACME_EMAIL}"

DOCKER_NETWORK="${ARG_NETWORK}"
DOCKER_ENDPOINT=tcp://docker-socket-proxy:2375
EOF

(
    cd "${ROOT}/traefik"

    export DOMAIN="${ARG_CORE_DOMAIN}"
    export ACME_EMAIL="${ARG_ACME_EMAIL}"
    export DOCKER_NETWORK="${ARG_NETWORK}"
    export DOCKER_ENDPOINT="tcp://docker-socket-proxy:2375"

    rm -f traefik.yaml >/dev/null 2>&1
    envsubst <traefik.yaml.template >traefik.yaml
) &
loading_spinner "Configuring traefik..." "Configured traefik"

bash "${SCRIPTS_DIR}/security/gen-ca-cert.sh" --force
bash "${SCRIPTS_DIR}/security/rotate-client-cert.sh"

bash "${SCRIPTS_DIR}/sftp/gen-host-key.sh" --force

(
    cd "${ROOT}"
    docker compose up -d
) &
loading_spinner "Starting..." "Started!"

# create a symlink to the easy-serve.sh script
# allowing the user to use the 'easy-serve' command
chmod +x "${ROOT}/easy-serve.sh"
ln -sf "${ROOT}/easy-serve.sh" /usr/local/bin/easy-serve

# print a final success block outlining the next steps
echo -e "Successfully installed $(mark "easy-serve") for $(mark "${set_domain}")!"
echo -e "You can now use the $(mark "easy-serve") command to manage your instances."
echo -e "Run $(mark "easy-serve --help") for more information."
echo -e "You can access the traefik dashboard at $(mark "https://traefik.${set_domain}")"

rm -f "${ROOT}/install.sh" >/dev/null 2>&1
