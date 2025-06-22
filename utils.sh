#!/bin/bash
check_for_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        printf "'terraform.tfvars' not found! Please add your Ubuntu Pro token to 'terraform.tfvars.example' and rename it to 'terraform.tfvars'.\n"
        exit 1
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

BOLD="\e[1m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"
