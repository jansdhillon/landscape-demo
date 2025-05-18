#!/bin/bash

ctrlc_count=0

LANDSCAPE_FQDN="landscape.example.com"
LANDSCAPE_MODEL_NAME="landscape-model"
LANDSCAPE_CONTROLLER_NAME="landscape-controller"
NUM_CLIENTS=3

function handle_ctrlc() {
    let ctrlc_count++
    echo
    if [[ $ctrlc_count == 1 ]]; then
        echo "Press CTRL+C again to exit"
    else
        echo "Cleaning up and exiting..."
        rm -rf server.pem
        sudo sed -i.bak "/$HAPROXY_IP[[:space:]]\+$LANDSCAPE_FQDN/d" /etc/hosts
        juju destroy-controller --no-prompt $LANDSCAPE_CONTROLLER_NAME --destroy-all-models --no-wait --force
        exit
    fi
}

trap handle_ctrlc SIGINT

juju bootstrap lxd $LANDSCAPE_CONTROLLER_NAME
juju add-model $LANDSCAPE_MODEL_NAME

# We can now add the Landscape Server unit and the other charms we need to run Landscape
juju deploy ch:landscape-server \
    --config landscape_ppa=ppa:landscape/self-hosted-24.04 \
    --revision 124 \
    --constraints mem=4096 \
    --channel stable

juju deploy ch:haproxy --config haproxy-cfg.yaml --channel stable --revision 75 
juju expose haproxy
juju deploy ch:postgresql --config postgresql-cfg.yaml --channel 14/stable --revision 363
juju deploy ch:rabbitmq-server --channel 3.9/stable --revision 188

# For Landscape Client to relate to in the future

juju deploy ubuntu -n $NUM_CLIENTS

# Next, setup the relations
juju relate landscape-server rabbitmq-server
juju relate landscape-server haproxy
juju integrate landscape-server:db postgresql:db-admin

# Wait for Landscape Server unit to become active
until (juju wait-for application landscape-server --query='name=="landscape-server" && (status=="active")') \
    && (juju wait-for application postgresql --query='name=="postgresql" && (status=="active")') \
    sleep 1
done

# Get the HAProxy IP
HAPROXY_IP=$(juju show-unit haproxy/0 | grep "public-address" | awk '{print $2}')
echo "$HAPROXY_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts >/dev/null

# Get the self-signed cert from the Landscape Server unit

echo | openssl s_client -connect $LANDSCAPE_FQDN:443 | openssl x509 | sudo tee server.pem

# base64 encode it to use for Landscape Client units

B64_CERT=$(cat server.pem | base64)

echo "Visit https://$LANDSCAPE_FQDN to finalize Landscape Server configuration,"
read -r -p "then press Enter to continue provisioning Landscape Client instances, or CTRL+C to exit..."

# Deploy Landscape Client

juju deploy ch:landscape-client --config account-name='standalone' \
    --config ping-url="http://$LANDSCAPE_FQDN/ping" \
    --config url="https://$LANDSCAPE_FQDN/message-system" \
    --config ssl-public-key=base64:$B64_CERT

# Relate it to Ubuntu

juju relate ubuntu landscape-client
