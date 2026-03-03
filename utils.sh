#!/bin/bash

# Detect terraform or opentofu; prefer opentofu.
if command -v tofu &>/dev/null; then
    TF_CMD=tofu
elif command -v terraform &>/dev/null; then
    TF_CMD=terraform
else
    echo "Error: neither 'tofu' nor 'terraform' found in PATH" >&2
    exit 1
fi

BOLD="\e[1m"
RED="\e[31m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"

check_for_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_bold_red_text "terraform.tfvars not found!"
        exit 1
    fi
}

cleanup() {
    local workspace_name="${1:-}"
    ./destroy.sh "$workspace_name"
    exit 1
}

get_tfvar() {
    local key="$1"
    local file="${2:-terraform.tfvars}"
    local line
    line=$(grep "^${key}[[:space:]]*=" "$file")
    if [[ $line =~ \".*\" ]]; then
        echo "$line" | sed 's/.*=[[:space:]]*"\(.*\)".*/\1/'
    else
        echo "$line" | sed 's/.*=[[:space:]]*\([^[:space:]#]*\).*/\1/'
    fi
}

print_bold_orange_text() {
    echo -e "${BOLD}${ORANGE}${1:-}${RESET_TEXT}"
}

print_bold_red_text() {
    echo -e "${BOLD}${RED}${1:-}${RESET_TEXT}"
}
