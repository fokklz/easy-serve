apt install -y git

git clone https://github.com/fokklz/easy-serve.git "${1:-easy-serve}"

chmod +x easy-serve/scripts/setup.sh
bash easy-serve/scripts/setup.sh
