#!/bin/bash

# Update and install basic tools
sudo apt-get update
sudo apt-get install -y zip curl wget jq

# Function to install jq from GitHub releases
install_jq() {
    JQ_LATEST=$(curl -s https://api.github.com/repos/stedolan/jq/releases/latest | jq -r '.tag_name')
    JQ_URL="https://github.com/stedolan/jq/releases/download/${JQ_LATEST}/jq-linux64"
    curl -L "$JQ_URL" -o /usr/local/bin/jq
    chmod +x /usr/local/bin/jq
    echo "jq installed"
}

# Function to install yq from GitHub releases
install_yq() {
    YQ_LATEST=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')
    YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_LATEST}/yq_linux_amd64"
    curl -L "$YQ_URL" -o /usr/local/bin/yq
    chmod +x /usr/local/bin/yq
    echo "yq installed"
}

# Function to install fzf from GitHub releases
install_fzf() {
    FZF_LATEST=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.tag_name')
    FZF_URL="https://github.com/junegunn/fzf/releases/download/${FZF_LATEST}/fzf-${FZF_LATEST}-linux_amd64.tar.gz"
    curl -L "$FZF_URL" | tar xz -C /usr/local/bin
    chmod +x /usr/local/bin/fzf
    echo "fzf installed"
}

# Check and install jq if not installed
if ! command -v jq &>/dev/null; then
    echo "jq could not be found, installing..."
    install_jq
else
    echo "jq is already installed."
fi

if ! command -v yq &>/dev/null; then
    echo "yq could not be found, installing..."
    install_yq
else
    echo "yq is already installed."
fi

if ! command -v fzf &>/dev/null; then
    echo "fzf could not be found, installing..."
    install_fzf
else
    echo "fzf is already installed."
fi

echo "All installations are completed."
