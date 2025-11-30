#!/bin/bash

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
    local text="${1:-}"
    echo -e "${BOLD}${ORANGE}${text}${RESET_TEXT}"
}

print_bold_red_text() {
    local text="${1:-}"
    echo -e "${BOLD}${RED}${text}${RESET_TEXT}"
}


check_for_and_b64_encode_ssl_item() {
    # Base64 encode an SSL cert OR key IF they exist. It's fine if omitted, means self-signed.
    path_to_ssl_item="${1:-}"
    b64_ssl_item=""
    if [ -n "${path_to_ssl_item:-}" ] && [ "${path_to_ssl_item:-}" != "null" ]; then
        printf "Using 'sudo' to read SSL cert/key...\n" >&2
        b64_ssl_item=$(sudo base64 "$path_to_ssl_item" 2>/dev/null)
        if [ -z "$b64_ssl_item" ]; then
            print_bold_red_text "Failed to encode SSL cert/key!" >&2
            exit 1
        fi
    fi
    echo "${b64_ssl_item}"
}

process_gpg_private_key() {
    local path_to_gpg_private_key="${1:-}"

    if [[ -z "$path_to_gpg_private_key" ]]; then
        print_bold_red_text "Error: GPG private key path required" >&2
        return 1
    fi

    printf "Using 'sudo' to read GPG private key...\n" >&2
    # Probably a less hacky way of doing this but this uses what we have (yq)
    sudo cp "$path_to_gpg_private_key" gpg_private_key
    sudo chown "$(whoami)" "gpg_private_key"
    # URL-encode it
    local gpg_private_key_content=$(yq -r 'load_str("gpg_private_key") | @uri' /dev/null)
    sudo rm gpg_private_key

    echo "$gpg_private_key_content"
}

deploy_landscape_client() {
    local workspace_name="${1:-}"

    if [[ -z "$workspace_name" ]]; then
        print_bold_red_text "Error: workspace_name required for deploy_landscape_client"
        return 1
    fi

    terraform apply -auto-approve \
        -var "workspace_name=${workspace_name}" \
        -target module.landscape_client
}

deploy_landscape_server() {
    local workspace_name="${1:-}"
    local b64_ssl_cert="${2:-}"
    local b64_ssl_key="${3:-}"
    local gpg_private_key_content="${4:-}"

    if [[ -z "$workspace_name" ]]; then
        print_bold_red_text "Error: workspace_name required for deploy_landscape_server"
        return 1
    fi
    if [ -n "${b64_ssl_cert:-}" ] && [ -n "${b64_ssl_key:-}" ]; then
        if ! terraform plan \
            -var "workspace_name=${workspace_name}" \
            -var "b64_ssl_cert=${b64_ssl_cert}" \
            -var "b64_ssl_key=${b64_ssl_key}" \
            -var "gpg_private_key_content=${gpg_private_key_content}"; then
            print_bold_red_text 'Error running plan!\n'
            cleanup "$workspace_name"
        fi

        if ! terraform apply -auto-approve \
            -var "workspace_name=${workspace_name}" \
            -var "b64_ssl_cert=${b64_ssl_cert}" \
            -var "b64_ssl_key=${b64_ssl_key}" \
            -var "gpg_private_key_content=${gpg_private_key_content}"; then
            print_bold_red_text 'Error running apply!\n'
            cleanup "$workspace_name"
        fi
    else
        if ! terraform plan -var "workspace_name=${workspace_name}" -var "gpg_private_key_content=${gpg_private_key_content}"; then
            print_bold_red_text 'Error running plan!\n'
            cleanup "$workspace_name"
        fi

        if ! terraform apply -auto-approve -var "workspace_name=${workspace_name}" -var "gpg_private_key_content=${gpg_private_key_content}"; then
            print_bold_red_text 'Error running apply!\n'
            cleanup "$workspace_name"
        fi
    fi
}

update_etc_hosts() {
    local haproxy_ip="${1:-}"
    local landscape_root_url="${2:-}"

    if [ -n "${haproxy_ip}" ] && [ -n "${landscape_root_url}" ]; then
        print_bold_orange_text "Using 'sudo' to modify /etc/hosts...\n"
        printf "%s %s\n" "$haproxy_ip" "$landscape_root_url" | sudo tee -a /etc/hosts >/dev/null
    else
        print_bold_red_text "Failed to retrieve HAProxy IP or Landscape root URL, aborting changes to /etc/hosts...\n"
    fi
}

BOLD="\e[1m"
RED="\e[31m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"
