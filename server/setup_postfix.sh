#!/bin/bash
set -x
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix

SMTP_HOST="$1"
SMTP_PORT="$2"
SMTP_USERNAME="$3"
SMTP_PASSWORD="$4"
SMTP_HOST="$5"
FQDN="$6"
DOMAIN="$7"

sudo postconf -e myhostname="$FQDN"
sudo postconf -e mydomain="$DOMAIN"
sudo postconf -e myorigin="$DOMAIN"
sudo postconf -e masquerade_domains="$DOMAIN"
sudo postconf -e mydestination=localhost
sudo postconf -e default_transport=smtp
sudo postconf -e relay_transport=smtp
sudo postconf -e relayhost="[${SMTP_HOST}]:${SMTP_PORT}"
sudo postconf -e smtp_sasl_auth_enable=yes
sudo postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
sudo postconf -e smtp_sasl_security_options=noanonymous
sudo postconf -e header_size_limit=4096000
sudo postconf -e smtp_use_tls=yes
sudo postconf -e smtp_tls_security_level=encrypt
sudo postconf -e smtp_sasl_tls_security_options=noanonymous
sudo sh -c "echo \"[$SMTP_HOST]:$SMTP_PORT $SMTP_USERNAME:$SMTP_PASSWORD\" > /etc/postfix/sasl_passwd"
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd.db
sudo rm /etc/postfix/sasl_passwd
sudo /etc/init.d/postfix restart
