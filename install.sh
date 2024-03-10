#!/bin/bash
# Path: install.sh
# Author: Fokko Vos
#
# Meant to simplify the installation process of easy-serve
# This script can be run piped using curl:
#     curl -sSL https://raw.githubusercontent.com/fokklz/easy-serve/main/install.sh | bash
#
# The goal is to make the installation process as simple as possible
# If the script is not being piped, it will run the setup.sh directly
#
# This script will be deleted by the setup.sh script

if [ -t 0 ]; then
    echo "Detected script is not being piped. Running setup.sh directly..."
    chmod +x ./scripts/setup.sh
    ./scripts/setup.sh
    exit 0
fi

apt install -y git

git clone https://github.com/fokklz/easy-serve.git "${NAME:-easy-serve}"
cd "${NAME:-easy-serve}" || exit
bash "scripts/setup.sh" </dev/tty
