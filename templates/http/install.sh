DOMAIN=$1
NAME=$2
INSTANCE=$3

cat <<EOF
TEMPLATE=http
INSTANCE_NAME="${NAME}"
INSTANCE_DOMAIN="${DOMAIN}"
EOF
