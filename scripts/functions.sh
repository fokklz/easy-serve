# Function to display the spinning loading symbol
loading_spinner() {
    local message=$1
    local finish=$2
    local spin='-\|/'
    local i=0
    local pid=$!
    trap 'error "An error occurred in the background command"' ERR
    # Keep spinning until the background process completes
    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 4))
        printf "\r ${spin:$i:1} ${message}"
        sleep .1
    done
    # Clear the loading spinner before finish display
    printf "\r%*s\r" $((${#message} + 3)) ""
    printf "\r ${COLOR_GREEN}✓${COLOR_RESET} ${finish}\n"
}

prompt_confirmation() {
    if [ "${FORCE:-false}" = true ]; then
        return 0
    fi

    read -p "$1 (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

error() {
    echo -e "${COLOR_RED}${1}${COLOR_RESET}"
    exit 1
}

mark() {
    value="${1}"

    if [ "${PLAIN:-false}" = true ]; then
        echo "${value}"
    else
        echo "${COLOR_CYAN}${value}${COLOR_RESET}"
    fi
}

function restart() {
    local service="${1}"

    (
        cd "${ROOT}"
        if [ -n "${service}" ]; then
            docker compose down "${service}"
            docker compose up -d "${service}"
        else
            docker compose down
            docker compose up -d
        fi
    )
}
