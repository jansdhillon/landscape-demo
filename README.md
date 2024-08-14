# Landscape Demo

You need the Multipass, LXD, and yq snap packages to be installed on your Linux machine to run a local Landscape demo. Optionally, you need the landscape-api snap package installed to perform headless Landscape configurations, without interacting with the Landscape GUI.

## Step 1. Install and configure prerequisites

Clone this repository and make scripts executable:

```bash
git clone git@github.com:rajannpatel/ubuntu-instances.git
cd ubuntu-instances
chmod +x *.sh
```

Install and configure the packages the scripts in this repository expect to find on your machine.

> ```bash
> sudo snap install yq
> sudo snap install multipass
> snap list lxd &> /dev/null && sudo snap refresh lxd --channel latest/stable || sudo snap install lxd --channel latest/stable
> ```

Initialize LXD

> ```bash
> lxd init --auto
> ```

For the LXD container to reach the external network, the MTU on the bridge must match the default network adapter. This extra step is necessary in some virtualized environments, such as Google Cloud's Compute Engine where the MTU is lower, or Oracle Cloud where jumbo frames are enabled by default, and the MTU is higher. This is not likely to impact you on most networks, where the default MTU is 1500.

```bash
read -r INTERFACE < <(ip route | awk '$1=="default"{print $5; exit}')
lxc network set lxdbr0 bridge.mtu=$(ip link show $INTERFACE | awk '/mtu/ {print $5}')
```

Edit the variables.txt file, only TOKEN, HOSTNAME, and LANDSCAPE_VERSION are mandatory. The HOSTNAME and DOMAIN will be combined by the add.sh script to create a fully qualified domain name (FQDN).

```text
EMAIL={EMAIL_ADDRESS}
TOKEN={PRO_TOKEN}
HOSTNAME={HOST_NAME}
DOMAIN={DOMAIN}
TIMEZONE={TIME_ZONE}
SMTP_HOST={SMTP_HOST}
SMTP_PORT={SMTP_PORT}
SMTP_USERNAME={SMTP_USERNAME}
SMTP_PASSWORD={SMTP_PASSWORD}
LANDSCAPE_VERSION={LANDSCAPE_VERSION}
CERTBOT={CERTBOT_INSTALL_METHOD}
SSL_CERTIFICATE_PATH={PATH_TO_CERT.PEM}
SSL_CERTIFICATE_KEY_PATH={PATH_TO_PRIVKEY.PEM}
SSL_CERTIFICATE_CHAIN_PATH={PATH_TO_CHAIN.PEM}
```

## Step 2. Decide between self-signed SSL and valid SSL certificates

To use self-signed SSL certificates, leave the CERTBOT variable, and all 3 SSL_ prefixed variables blank, in the variables.txt file:

```text
CERTBOT=
SSL_CERTIFICATE_PATH=
SSL_CERTIFICATE_KEY_PATH=
SSL_CERTIFICATE_CHAIN_PATH=
```

To use valid SSL certificates on your Landscape Server LXD instance, there are two ways to obtain and install them.

1.  For Internet-facing Landscape Server installations, with unrestricted incoming Port 80 and 443 traffic, specify `CERTBOT=apt` or `CERTBOT=snap` in variables.txt to install the certbot package and configure Apache.

2.  For instances with restricted inbound connectivity on Port 80 and 443, not installing certbot on Landscape Server makes sense. Setting `CERTBOT=` to equal nothing will result in certbot not being installed in the Landscape Server LXD instance. Instead of using certbot within the Landscape Server LXD instance to acquire and configure SSL certificates, the paths to the certificates can be provided as the values for the SSL_CERTIFICATE_PATH, SSL_CERTIFICATE_KEY_PATH, and SSL_CERTIFICATE_CHAIN_PATH variables.

To obtain a wildcard subdomain SSL certificate from LetsEncrypt, run:

```bash
sudo snap install certbot --classic
sudo certbot certonly --manual --preferred-challenges dns -d "*.$(grep '^DOMAIN=' variables.txt | cut -d'=' -f2)"
```

-  **cert.pem**: This is the server certificate issued for your domain. It is your primary certificate that identifies your server.
-  **chain.pem**: This file contains the intermediate CA certificates needed to establish a chain of trust from your server certificate to the root CA certificate. In many cases, this file is what you need for the CA certificate(s).
-  **privkey.pem**: This is your private key associated with the server certificate. It should be kept secure and private.
-  **fullchain.pem**: This file includes both your server certificate (cert.pem) and the intermediate CA certificates (chain.pem), providing a complete certificate chain. Since the cert.pem and chain.pem files are independently configured, this file does not need to be used.

An example of a valid variables.txt appears below, with tokens and keys redacted.

```text
EMAIL=rajan.patel@canonical.com
TOKEN=REDACTED
HOSTNAME=landscapedemo
DOMAIN=rajanpatel.com
TIMEZONE=America/New_York
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=REDACTED
LANDSCAPE_VERSION=24.04
CERTBOT=
SSL_CERTIFICATE_FILE=/etc/letsencrypt/live/rajanpatel.com/cert.pem
SSL_CERTIFICATE_KEY_FILE=/etc/letsencrypt/live/rajanpatel.com/privkey.pem
SSL_CERTIFICATE_CHAIN_FILE=/etc/letsencrypt/live/rajanpatel.com/chain.pem
```

## Step 4. Run scripts

[./add.sh](add.sh) will create Ubuntu instances, starting with Landscape, followed by Ubuntu instances that will enroll with that Landscape instance.

All new instances will be named with a common prefix, to keep things organized. The prefix is in `DAYHHMM` format

Landscape Server will be launched in an Ubuntu 24.04 LXD container.

The add.sh is going to launch arch="amd64" Ubuntu instances as follows:
- lxd_virtualmachines=("jammy" "noble" "focal")
- lxd_containers=("jammy" "noble" "bionic")
- multipass_virtualmachines=("core24")

Older fingerprints of each image will be used, when available, for demoing security patching with Livepatch and Landscape.

[./stop.sh](stop.sh) can stop every Ubuntu instance with your chosen `DAYHHMM` prefix.

[./remove.sh](stop.sh) can delete sets of LXD containers and virtual machines, and Multipass virtual machines. If more than one instance is detected with a `DAYHHMM` prefix, it will be added to a list. Choose which grouping of containers and virtual machines you wish to delete.

---

## TODO:

- Run `pro fix` commands on each Landscape-managed Ubuntu instance after provisioning. This simulates patch drift between various machines, and makes for more interesting demos.
- snapshot.sh will take a point in time snapshot of Landscape and a selection of LXD and Multipass instances.
- restore.sh will restore a point in time snapshot of Landscape and a selection of LXD and Multipass instances.