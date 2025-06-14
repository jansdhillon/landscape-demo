#!/bin/bash

SSL_KEY_PATH="$1"
SSL_CERT_PATH="$2"

printf "Reading SSL certificate and key with 'sudo'...\n" >&2

B64_ENCODED_KEY=$(sudo base64 "$SSL_KEY_PATH" | tr -d "\n")
B64_ENCODED_CERT=$(sudo base64 "$SSL_CERT_PATH" | tr -d "\n")

echo "{\"b64_encoded_key\": \"$B64_ENCODED_KEY\", \"b64_encoded_cert\": \"$B64_ENCODED_CERT\"}"
