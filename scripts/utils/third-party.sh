DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source "${DIR}/../globals.sh"

(
    # Update and install basic tools
    sudo apt-get update
    sudo apt-get install -y zip curl wget jq gettext-base

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
