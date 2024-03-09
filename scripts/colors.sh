#!/bin/bash

# Color definitions to simplify the usage of colors in scripts
# Contains also some functions which simplify the usage of colors & will apply reset automatically

COLOR_RED="\033[38;2;229;57;53m"
COLOR_PINK="\033[38;2;244;67;54m"
COLOR_PURPLE="\033[38;2;142;36;170m"
COLOR_DEEP_PURPLE="\033[38;2;94;53;177m"
COLOR_INDIGO="\033[38;2;57;73;171m"
COLOR_BLUE="\033[38;2;30;136;229m"
COLOR_LIGHT_BLUE="\033[38;2;3;169;244m"
COLOR_CYAN="\033[38;2;0;172;193m"
COLOR_TEAL="\033[38;2;0;150;136m"
COLOR_GREEN="\033[38;2;67;160;71m"
COLOR_LIGHT_GREEN="\033[38;2;104;159;56m"
COLOR_LIME="\033[38;2;205;220;57m"
COLOR_YELLOW="\033[38;2;255;235;59m"
COLOR_AMBER="\033[38;2;255;193;7m"
COLOR_ORANGE="\033[38;2;255;152;0m"
COLOR_DEEP_ORANGE="\033[38;2;255;87;34m"
COLOR_BROWN="\033[38;2;121;85;72m"
COLOR_GREY="\033[38;2;158;158;158m"
COLOR_BLUE_GREY="\033[38;2;96;125;139m"

COLOR_BOLD="\033[1m"
COLOR_UNDERLINE="\033[4m"
COLOR_RESET="\033[0m"

# Color
c() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${COLOR_RESET}"
}

# Color and Bold
cb() {
    local color=$1
    local message=$2
    echo -e "${COLOR_BOLD}${color}${message}${COLOR_RESET}"
}

# Color and Underline
cu() {
    local color=$1
    local message=$2
    echo -e "${COLOR_UNDERLINE}${color}${message}${COLOR_RESET}"
}

# Color, Bold and Underline
cbu() {
    local color=$1
    local message=$2
    echo -e "${COLOR_BOLD}${COLOR_UNDERLINE}${color}${message}${COLOR_RESET}"
}
