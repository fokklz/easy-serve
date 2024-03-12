# ----------------------------------------- //
#  // ---- COMMAND MANAGEMENT FUNCTIONS --- //
# ----------------------------------------- //

# Function to read and parse global options and commands from the JSON file
function read_config() {
    jq -r "$1" "${SCRIPTS_DIR}/commands.json"
}

# Function to print the help message in a two-column layout
function print_help() {
    local command_name=$1

    if [[ -z $command_name ]]; then
        # Global help page
        echo "Usage: $(basename "$0") COMMAND [OPTIONS]"
        echo
        echo -e "$(read_config '.description')"
        echo
        echo "Commands:"
        read_config '.commands[] | "\(.name)\t\(.description)"' | while IFS=$'\t' read -r cmd desc; do
            printf "  %-20s %s\n" "$cmd" "$desc"
        done
        echo
        echo "Global Options:"
        read_config '.globalOptions[] | "\(.flag)\t\(.description)"' | while IFS=$'\t' read -r flag desc; do
            printf "  %-20s %s\n" "$flag" "$desc"
        done
    else
        # Command-specific help page
        local cmd=$(read_config ".commands[] | select(.name == \"$command_name\")")
        local desc=$(jq -r '.description' <<<"$cmd")
        local usage=$(jq -r '.usage' <<<"$cmd")

        echo "Usage: $(basename "$0") $command_name $usage [OPTIONS]"
        echo
        echo -e "$desc"
        echo
        if jq -r '.options[]?' <<<"$cmd" | grep -q .; then
            echo "Options:"
            jq -r '.options[] | "\(.flag)\t\(.description)"' <<<"$cmd" | while IFS=$'\t' read -r flag desc; do
                printf "  %-20s %s\n" "$flag" "$desc"
            done
            echo
        fi
        read_config '.globalOptions[] | "\(.flag)\t\(.description)"' | while IFS=$'\t' read -r flag desc; do
            printf "  %-20s %s\n" "$flag" "$desc"
        done
    fi
}

# Function to print the version of the script
function print_version() {
    echo "Version: $(read_config '.version')"
}

# Function to Map shorthand options to their long counterparts
function map_short_options() {
    case "$1" in
    h)
        echo "--help"
        ;;
    v)
        echo "--version"
        ;;
    f)
        echo "--force"
        ;;
    d)
        echo "--debug"
        ;;
    *)
        echo -e "${COLOR_YELLOW}Unknown option: -$1${COLOR_RESET}" >/dev/tty
        ;;
    esac
}

# Funtion that Assigns the arguments to the variables with the names provided
function named_args() {
    local i=0
    local min_length=0
    local usage=""
    local clean_args=()
    local modifier=()

    for arg in "${@}"; do
        # apply modifier if present
        if [[ "$arg" == *"|"* ]]; then
            IFS='|' read -r arg modifier <<<"$arg"
            modifier+=("${modifier,,}")
        else
            modifier+=("-")
        fi

        # when the name is uppercase, it is required
        if [[ "$arg" == *[[:upper:]]* ]]; then
            ((min_length++))
            usage+="<${arg,,}> "
        else
            usage+="[${arg,,}] "
        fi

        clean_args+=("$arg")
    done

    declare -g "COMMAND_USAGE=${usage}"
    if [ "${FLAG_USAGE}" = true ]; then
        echo "${COMMAND_USAGE}"
        exit 0
    fi

    for name in "${clean_args[@]}"; do

        value="${ARGS[$i]}"

        if [ -z "${value}" ]; then
            break
        fi

        mod="${modifier[$i]}"
        if [ "${mod}" != "-" ]; then
            case "${mod}" in
            "lower")
                value="${value,,}"
                ;;
            "upper")
                value="${value^^}"
                ;;
            esac
        fi

        declare -g "${name}=${value}"
        unset value
        ((i++))
    done
}

# ----------------------------------------- //
#  // --- INSTANCE MANAGEMENT FUNCTIONS --- //
# ----------------------------------------- //

# Function to resolve a instance by name or domain
function get_instance {
    local type=$1 # names or domains
    local name=$2

    echo "$(jq -r --arg name "$name" --arg type "$type" '.[$type][$name]' "$INDEX_FILE")"
}

# Function to get the available actions for an instance
function get_available_actions {
    local instance=$1
    local options_str=""

    # Goes through all the .sh files in the instance directory and adds them to the options string
    for file in "${instance}"/*.sh; do
        available_action=$(basename "$file" .sh)
        options_str+="$(mark "$available_action" "${COLOR_BOLD}"), "
    done

    echo -e "${options_str%, }"
}

# Function to check if a type is valid (exists in the templates directory)
function is_valid_type() {
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
function is_valid_name() {
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
function is_valid_domain() {
    local domain=$1

    # If the domain is empty, return early
    if [[ -z "${domain}" ]]; then
        echo 1
        return
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

# Function to restart all or a specific service(s)
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

# -------------------------------------------------------- //
#  // --- USER EXPERIENCE & INPUT MANAGEMENT FUNCTIONS --- //
# -------------------------------------------------------- //

# Function to display the spinning loading symbol
function loading_spinner() {
    local message=$1
    local finish_message=$2
    local pid=$!
    local cols=$(tput cols)
    # Spinner characters
    local spin='-\|/'
    # Initial spinner position
    local i=0

    echo

    # Setup trap to catch and handle errors
    trap 'kill $pid 2>/dev/null; tput cnorm; tput ed; echo; exit 1' ERR SIGHUP SIGINT SIGTERM

    # Save cursor position & hide cursor
    tput sc
    tput civis

    # Wait for the background process to complete
    while kill -0 $pid 2>/dev/null; do

        printf '%*s' "$((${#message} + 2))"
        # Save cursor position, move to bottom line
        #tput sc
        tput rc

        # Move cursor one line down
        tput cud1
        tput cr
        # Display spinner and message
        printf "\r ${spin:i++%${#spin}:1} $message"

        # Clear from cursor to the end of line to ensure no remnants
        tput el
        # Move cursor right
        tput cr
        # Move cursor one line up
        tput cuu1

        # Remember the position to clear later
        #local current_line=$(tput lines)
        #local current_col=$((${#message} + 2))

        # Spinner frame rate
        sleep .05
        tput sc

        # Clear the previous spinner message to avoid conflicts with subprocess output
        #tput cup $current_line 0
        #printf '%*s' $current_col
        #tput cup $current_line 0
    done

    tput cup $(tput lines) 0
    tput ed
    tput cuu1

    if [[ " ${finish_message[*]} " == *"\\n"* ]]; then
        local index=0
        IFS=$'\n' read -r -a core_finish_message_array <<<"${finish_message[*]}"
        for message in "${core_finish_message_array[@]}"; do
            if [ $index -eq 0 ]; then
                echo -e "\n ${COLOR_GREEN}✓${COLOR_RESET} $message"
            else
                echo -e "    $message"
            fi

            ((index++))
        done
    else
        echo -e "\n ${COLOR_GREEN}✓${COLOR_RESET} $finish_message"
    fi

    # Restore cursor visibility
    tput cnorm
}

# Function to ask for user input based on a message, a regex pattern, an optional default value, and a variable to store the input
function ask_input() {
    local prompt_message="$1"
    local regex_pattern="$2"
    local default_value="$3"
    local variable_name="$4"
    local user_input=""

    while true; do
        echo -n "${prompt_message}"
        [[ -n "$default_value" && -z "$user_input" ]] && echo -n -e " [${COLOR_CYAN}${default_value}${COLOR_RESET}]"
        echo -n ": "
        read user_input

        # Use default if no input is given and it's the first iteration
        [[ -z "$user_input" && -n "$default_value" ]] && user_input="$default_value"

        # Check if the input matches the regex pattern
        if [[ $user_input =~ $regex_pattern ]]; then
            declare -g "$variable_name=$user_input"
            break
        else
            echo "Invalid input, please try again." >&2
            user_input="" # Reset user_input to show default value prompt again if needed
        fi
    done
}

# Function to prompt the user for confirmation will eval to true if the force flag is set
function prompt_confirmation() {
    if [[ "${FORCE:-false}" = true ]]; then
        return 0
    fi

    read -p "$1 (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to print an error message and exit the script
function error() {
    if [[ $FLAG_PLAIN = true ]]; then
        echo "${1}"
    else
        echo -e "${COLOR_RED}${1}${COLOR_RESET}"
    fi
    exit 1
}

# Function to mark a string with a color
function mark() {
    value="${1}"
    color="${2:-${COLOR_CYAN}}"

    if [[ $FLAG_PLAIN = true ]]; then
        echo "${value}"
    else
        echo -e "${color}${value}${COLOR_RESET}"
    fi
}

function warning() {
    if [[ $FLAG_PLAIN = true ]]; then
        echo "${1}"
    else
        echo -e "${COLOR_YELLOW}${1}${COLOR_RESET}"
    fi
}
