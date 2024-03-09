apt install -y git

git clone https://github.com/fokklz/easy-serve.git "${NAME:-easy-serve}"

chmod +x "${NAME:-easy-serve}/scripts/setup.sh"
bash "${NAME:-easy-serve}/scripts/setup.sh" </dev/tty
