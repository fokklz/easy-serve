# Function to display the spinning loading symbol
loading_spinner() {
    local message=$1
    local finish=$2
    local spin='-\|/'
    local i=0
    local pid=$!
    trap 'error "An error occurred in the background command\n $ERR"' ERR
    local cols=$(tput cols)

    # Start the spinner in the last line by moving the cursor down
    tput cud1

    # Keep spinning until the background process completes
    while kill -0 $pid 2>/dev/null; do
        # Move cursor up one line, spin, and move back down
        tput cud1
        printf "\r ${spin:$i:1} ${message}"
        # Clear the rest of the line by overwriting with spaces
        printf '%*s' $(($cols - ${#message} - 3))
        # Move back to the start of the spinner position
        printf '\r'
        tput cuu1
        i=$(((i + 1) % 4))
        sleep .1
    done

    # Clear the spinner line completely using backspaces followed by spaces
    tput cuu1
    printf '\r%*s' $cols
    printf '\r'
    # Display the finish message (essentially empty line + message (filled empty))
    printf "$(printf '%*s' $cols)\n${COLOR_GREEN}✓${COLOR_RESET} ${finish}$(printf '%*s' $cols)\r"
}

# Function to ask for user input based on a message, a regex pattern, an optional default value, and a variable to store the input
ask_input() {
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

# Function to collect multiple inputs with the first input having an optional default value
collect_multiple_inputs() {
    local prompt_message="$1"
    local regex_pattern="$2"
    local default_value="$3"
    local collected_values=()
    local input_value
    local first_input=true

    while true; do
        if [ "$first_input" = true ]; then
            ask_input "$prompt_message" "$regex_pattern" "$default_value" | read -r input_value
            first_input=false
        else
            ask_input "$prompt_message" "$regex_pattern" | read -r input_value
        fi

        # If input is empty, break after the first input has been collected
        if [ -z "$input_value" ]; then
            break
        fi

        collected_values+=("$input_value") # Add the valid input to the array
    done

    # Echo collected values, joined by a space
    local IFS=' ' # Internal Field Separator set to space
    echo "${collected_values[*]}"
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
