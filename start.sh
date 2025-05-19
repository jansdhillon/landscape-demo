#!/bin/bash

set -eE -o pipefail

LANDSCAPE_FQDN="landscape.example.com"
LANDSCAPE_MODEL_NAME="landscape"


while [[ -z $PRO_TOKEN ]]; do
    echo -n "'PRO_TOKEN' is not set. Visit https://ubuntu.com/pro/dashboard to get it,"
    read -r -p " and enter it here, or press CTRL+C to exit: " PRO_TOKEN
done

cleanup() {
    echo "Cleaning up model and exiting..."
    rm -rf server.pem
    echo "Modifying /etc/hosts requires elevated privileges."
    sudo sed -i.bak "/$HAPROXY_IP[[:space:]]\+$LANDSCAPE_FQDN/d" /etc/hosts
    juju destroy-model --no-prompt $LANDSCAPE_MODEL_NAME --no-wait --force
    exit
}

trap cleanup SIGINT
trap cleanup ERR

juju add-model $LANDSCAPE_MODEL_NAME

echo "Provisioning machines..."

# Add the Landscape Server unit and the other apps we need to run Landscape
# based on https://github.com/canonical/landscape-bundles/blob/scalable-stable/bundle.yaml

juju deploy ch:landscape-server \
    --config landscape_ppa=ppa:landscape/self-hosted-beta \
    --constraints mem=4096 \
    --base ubuntu@22.04

juju deploy ch:haproxy \
    --channel stable \
    --revision 75 \
    --config default_timeouts="queue 60000, connect 5000, client 120000, server 120000" \
    --config global_default_bind_options=no-tlsv10 \
    --config services="" \
    --config ssl_cert=SELFSIGNED \
    --base ubuntu@22.04

juju expose haproxy

juju deploy ch:postgresql \
    --config plugin_plpython3u_enable=true \
    --config plugin_ltree_enable=true \
    --config plugin_intarray_enable=true \
    --config plugin_debversion_enable=true \
    --config plugin_pg_trgm_enable=true \
    --config experimental_max_connections=500 \
    --channel 14/stable \
    --revision 468 \
    --base ubuntu@22.04 \
    --constraints mem=2048 \
    -n 3

juju deploy ch:rabbitmq-server \
    --channel 3.9/stable \
    --revision 188 \
    --base ubuntu@22.04 \
    --config consumer-timeout=259200000

# For Landscape Client to use in the future

juju deploy ubuntu -n 3

# Create VMs

juju add-machine -n 2 --constraints="virt-type=virtual-machine"

juju add-unit -n 2 ubuntu --to 9,10

printf "Waiting for Ubuntu instances to become active"
for i in {0..4}; do
    while true; do
        status=$(juju status "ubuntu/$i" --format=yaml | yq '.applications.ubuntu.application-status.current')
        if [[ "$status" == "active" ]]; then
            echo "done."
            break
        fi
        printf "."
        sleep 1
    done
    echo "Attaching Ubuntu Pro token..."
    juju ssh "ubuntu/$i" "sudo pro attach $PRO_TOKEN"
done

# Next, setup the relations

juju relate landscape-server rabbitmq-server
juju relate landscape-server haproxy
juju integrate landscape-server:db postgresql:db-admin

printf "Waiting for the Landscape Server and PostgreSQL apps to become active"
while true; do
    ls_status=$(juju status landscape-server --format=yaml | yq '.applications.landscape-server.application-status.current')
    pg_status=$(juju status postgresql --format=yaml | yq '.applications.postgresql.application-status.current')

    if [[ "$ls_status" == "active" && "$pg_status" == "active" ]]; then
        echo "done."
        break
    fi
    printf "."
    sleep 1
done

# Get the HAProxy IP

HAPROXY_IP=$(juju show-unit "haproxy/0" | yq '."haproxy/0".public-address')
echo "$HAPROXY_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts > /dev/null

# Get the self-signed cert
echo | openssl s_client -connect "$HAPROXY_IP:443" | openssl x509 | sudo tee server.pem > /dev/null

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

echo "Setup complete! Login at https://$LANDSCAPE_FQDN to approve the pending instances."
