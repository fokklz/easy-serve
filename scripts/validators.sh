# Function to check if a type is valid (exists in the templates directory)
is_valid_template() {
    local type=$1

    # If the type is empty, return early
    if [[ -z "${type}" ]]; then
        echo 1
        return
    fi

    # If the directory exists in the templates directory we assume it is a valid type
    if [ -d "${TEMPLATE_ROOT}/${type}" ]; then
        echo 0
    else
        echo 1
    fi
}

# Function to check if a name is valid and not in use (1 wrong format, 2 already in use)
is_valid_name() {
    local name=$1

    # If the name is empty, return early
    if [[ -z "${name}" ]]; then
        echo 1
        return
    fi

    if [[ $name =~ $NAME_REGEX ]]; then
        # Use jq to check if the name is already contained in the names object in the index file
        if jq -e --arg name "$name" '.names.[$name] | select(. != null)' "$INDEX_FILE" &>/dev/null; then
            echo 2
        else
            echo 0
        fi
    else
        echo 1
    fi
}

# Function to check if a domain is valid and not in use (1 wrong format, 2 already in use)
is_valid_domain() {
    local domain=$1

    # If the domain is empty, return early
    if [[ -z "${domain}" ]]; then
        echo 1
        return
    fi

    # if the provided domain is something and does not contain a dot, append the global DOMAIN
    if [[ ! -z "${domain}" ]] && [[ "${domain}" != *.* ]]; then
        domain="${domain}.${DOMAIN}"
    fi

    if [[ $domain =~ $DOMAIN_REGEX ]]; then
        # Use jq to check if the domain is already contained in the domains object in the index file
        if jq -e --arg domain "$domain" '.domains.[$domain] | select(. != null)' "$INDEX_FILE" &>/dev/null; then
            echo 2
        else
            DOMAINS=()
            if ping -c 4 "traefik.${DOMAIN}" &>/dev/null; then
                DATA=$(curl -sS --cert-type P12 --cert $(cat ${SEC_CERT}) "https://traefik.${DOMAIN}/api/rawdata")
                DOMAINS=$(echo "${DATA}" | jq -r '.routers | .[] | select(.rule | startswith("Host")) | .rule' | sed -E 's/Host\(`(.*)`\)/\1/')
            fi

            if [[ " ${DOMAINS[@]} " =~ " ${domain} " ]]; then
                echo 2
                return
            fi

            echo 0
        fi
    else
        echo 1
    fi
}
