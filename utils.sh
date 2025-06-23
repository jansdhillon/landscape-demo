#!/bin/bash
check_for_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_bold_red_text "terraform.tfvars not found!"
        exit
    fi
}

get_tfvar() {
    local key="$1"
    local file="${2:-terraform.tfvars}"
    local line=$(grep "^${key}[[:space:]]*=" "$file")

    if [[ $line =~ \".*\" ]]; then
        # Quoted
        echo "$line" | sed 's/.*=[[:space:]]*"\(.*\)".*/\1/'
    else
        # Unquoted
        echo "$line" | sed 's/.*=[[:space:]]*\([^[:space:]#]*\).*/\1/'
    fi
}

print_bold_orange_text() {
    local text="$1"
    echo -e "${BOLD}${ORANGE}${text}${RESET_TEXT}"
}

print_bold_red_text() {
    local text="$1"
    echo -e "${BOLD}${RED}${text}${RESET_TEXT}"
}

BOLD="\e[1m"
RED="\e[31m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"
