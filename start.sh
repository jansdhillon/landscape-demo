#!/bin/bash

set -eE -o pipefail

LANDSCAPE_FQDN="landscape.example.com"
LANDSCAPE_MODEL_NAME="landscape"
NUM_CLIENTS=3
TOKEN="$(grep '^TOKEN=' variables.txt | cut -d'=' -f2)" # From ubuntu.com/pro/dashboard

cleanup() {
    echo "Cleaning up and exiting..."
    rm -rf server.pem
    sudo sed -i.bak "/$HAPROXY_IP[[:space:]]\+$LANDSCAPE_FQDN/d" /etc/hosts
    juju destroy-model --no-prompt $LANDSCAPE_MODEL_NAME --no-wait --force
    exit
}

trap cleanup SIGINT
trap cleanup ERR
trap 'echo "Done."' EXIT

juju add-model $LANDSCAPE_MODEL_NAME

# Add the Landscape Server unit and the other charms we need to run Landscape
juju deploy ch:landscape-server \
    --config landscape_ppa=ppa:landscape/self-hosted-beta \
    --revision 124 \
    --constraints mem=4096 \
    --channel stable

juju deploy ch:haproxy --channel stable --revision 75 \
    --config default_timeouts="queue 60000, connect 5000, client 120000, server 120000" \
    --config global_default_bind_options=no-tlsv10 \
    --config services="" \
    --config ssl_cert=SELFSIGNED
juju expose haproxy

juju deploy ch:postgresql --config plugin_plpython3u_enable=true \
    --config plugin_ltree_enable=true \
    --config plugin_intarray_enable=true \
    --config plugin_debversion_enable=true \
    --config plugin_pg_trgm_enable=true \
    --channel 14/stable \
    --revision 363
juju deploy ch:rabbitmq-server --channel 3.9/stable --revision 188

# For Landscape Client to use in the future

juju deploy ubuntu -n $NUM_CLIENTS

echo "Attaching Ubuntu Pro tokens..."
for ((i = 0; i < NUM_CLIENTS; i++)); do
    while true; do
        status=$(juju status ubuntu/$i --format=yaml | yq '.applications.ubuntu.application-status.current')
        if [[ "$status" == "active" ]]; then
            break
        fi
        sleep 1
    done
    juju ssh "ubuntu/$i" "sudo pro attach $TOKEN"
done

# Next, setup the relations
juju relate landscape-server rabbitmq-server
juju relate landscape-server haproxy
juju integrate landscape-server:db postgresql:db-admin

echo -n "Waiting for Landscape to become active (use \"juju status -m $LANDSCAPE_MODEL_NAME --watch 2s\" in another terminal for a detailed, live view)"

while true; do
    ls_status=$(juju status landscape-server --format=yaml | yq '.applications.landscape-server.application-status.current')
    pg_status=$(juju status postgresql --format=yaml | yq '.applications.postgresql.application-status.current')

    if [[ "$ls_status" == "active" && "$pg_status" == "active" ]]; then
        echo "done."
        break
    fi
    echo -n "."
    sleep 1
done

# Get the HAProxy IP
HAPROXY_IP=$(juju show-unit haproxy/0 | yq .haproxy/0.public-address | cut -d/ -f1)
echo "$HAPROXY_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts >/dev/null

# Get the self-signed cert
echo | openssl s_client -connect $HAPROXY_IP:443 | openssl x509 | sudo tee server.pem

# base64 encode it to use for Landscape Client units

B64_CERT=$(cat server.pem | base64)

echo "Visit https://$LANDSCAPE_FQDN to finalize Landscape Server configuration,"
read -r -p "then press Enter to continue provisioning Landscape Client instances, or CTRL+C to exit..."

# Deploy Landscape Client

juju deploy ch:landscape-client --config account-name='standalone' \
    --config ping-url="http://$HAPROXY_IP/ping" \
    --config url="https://$HAPROXY_IP/message-system" \
    --config ssl-public-key="base64:$B64_CERT" \
    --config ppa="ppa:landscape/self-hosted-beta"

# Relate it to Ubuntu

juju relate ubuntu landscape-client
