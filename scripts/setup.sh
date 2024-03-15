DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

hostnames=($(hostname -I))

http_ip_address=""
sftp_ip_address=""
sftp_port=""
set_domain=""

source "${DIR}/globals.sh"

if [ -f "${DIR}/../.env" ]; then
    rm -f "${ROOT}/install.sh" >/dev/null 2>&1
    error "Seems to be already installed. Exiting."
fi

(
    # Update and install basic tools
    sudo apt-get update
    sudo apt-get install -y zip curl wget jq

    # Check if docker & docker compose command is already installed
    if ! command -v docker &>/dev/null || ! command -v docker compose &>/dev/null; then
        echo "docker command could not be found, installing..."
        curl -sSL https://get.docker.com/ | CHANNEL=stable sh
    else
        echo "docker command is already installed."
    fi

    # Check if jq command is already installed
    if ! command -v jq &>/dev/null; then
        echo "jq could not be found, installing..."
        JQ_LATEST=$(curl -s https://api.github.com/repos/stedolan/jq/releases/latest | jq -r '.tag_name')
        JQ_URL="https://github.com/stedolan/jq/releases/download/${JQ_LATEST}/jq-linux64"
        curl -L "$JQ_URL" -o /usr/local/bin/jq
        chmod +x /usr/local/bin/jq
        echo "jq installed"
    else
        echo "jq is already installed."
    fi

    # Check if yq command is already installed
    if ! command -v yq &>/dev/null; then
        echo "yq could not be found, installing..."
        YQ_LATEST=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')
        YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_LATEST}/yq_linux_amd64"
        curl -L "$YQ_URL" -o /usr/local/bin/yq
        chmod +x /usr/local/bin/yq
        echo "yq installed"
    else
        echo "yq is already installed."
    fi

    # Check if fzf command is already installed
    if ! command -v fzf &>/dev/null; then
        echo "fzf could not be found, installing..."
        FZF_LATEST=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.tag_name')
        FZF_URL="https://github.com/junegunn/fzf/releases/download/${FZF_LATEST}/fzf-${FZF_LATEST}-linux_amd64.tar.gz"
        curl -L "$FZF_URL" | tar xz -C /usr/local/bin
        chmod +x /usr/local/bin/fzf
        echo "fzf installed"
    else
        echo "fzf is already installed."
    fi
) &
loading_spinner "Installing basic tools..." "Basic tools installed"

ask_input "Please enter the IP address for the HTTP server" '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' "${hostnames[0]}" http_ip_address

ask_input "Please enter the IP address for the SFTP server" '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' "${http_ip_address}" sftp_ip_address

ask_input "Please enter the port for the SFTP server. Recommended to change" '^[0-9]+$' "2233" sftp_port

ask_input "Please enter the domain name" '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' "" set_domain

if ! docker network inspect traefik_network >/dev/null 2>&1; then
    docker network create traefik_network
fi

cat >"${ROOT}/.env" <<EOF
HTTP_IP_ADDRESS="${http_ip_address}"
SFTP_IP_ADDRESS="${sftp_ip_address}"

HTTP_PORT="80"
HTTPS_PORT="443"
SFTP_PORT="${sftp_port}"

DOMAIN="${set_domain}"
EOF

bash "${SCRIPTS_DIR}/security/gen-ca-cert.sh"
bash "${SCRIPTS_DIR}/security/rotate-client-cert.sh"

bash "${SCRIPTS_DIR}/sftp/gen-host-key.sh"

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
