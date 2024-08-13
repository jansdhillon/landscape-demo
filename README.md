# Landscape Demo

You need the Multipass, LXD, and yq snap packages to be installed on your Linux machine to run a local Landscape demo. Optionally, you need the landscape-api snap package installed to perform headless Landscape configurations, without interacting with the Landscape GUI.

> ```bash
> sudo snap install yq
> sudo snap install multipass
> snap list lxd &> /dev/null && sudo snap refresh lxd --channel latest/stable || sudo snap install lxd --channel latest/stable
> ```

Configure LXD
> ```bash
> lxd init --auto
> ```

For the LXD container to reach the external network, the MTU on the bridge must match the default network adapter. This is necessary in some virtualized environments, such as Google Cloud's Compute Engine.
```bash
read -r INTERFACE < <(ip route | awk '$1=="default"{print $5; exit}')
lxc network set lxdbr0 bridge.mtu=$(ip link show $INTERFACE | awk '/mtu/ {print $5}')
```

## Step 1. Deploy Landscape

Deploy to LXD container using cloud-init.yaml

1.  Download the latest cloud-init.yaml:

    > ```bash
    > curl -o cloud-init.yaml https://raw.githubusercontent.com/canonical/landscape-scripts/main/provisioning/cloud-init-quickstart.yaml
    > ```

2.  Create a variables.txt file with the following contents.

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

    An example of my variables.txt appears below, with tokens and keys redacted.

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
    CERTBOT=''
    SSL_CERTIFICATE_FILE=/etc/letsencrypt/live/rajanpatel.com/cert.pem
    SSL_CERTIFICATE_KEY_FILE=/etc/letsencrypt/live/rajanpatel.com/privkey.pem
    SSL_CERTIFICATE_CHAIN_FILE=/etc/letsencrypt/live/rajanpatel.com/chain.pem
    ```

3.  Update cloud-init.yaml with the contents of variables.txt

    > ```bash
    > while IFS='=' read -r key value; do sed -i "s|{% set $key = '.*' %}|{% set $key = '$value' %}|" cloud-init.yaml; done < variables.txt
    > ```

4.  Configure SSL with variables.txt

    For Internet-facing Landscape Server installations, with unrestricted incoming Port 80 and 443 traffic, specify `CERTBOT=apt` or `CERTBOT=snap` cloud-init to install the **certbot** package and configure Apache. Leaving the CERTBOT variable blank `CERTBOT=''` will result in certbot not being installed. Not installing certbot on Landscape Server makes sense for instances with restricted inbound connectivity on Port 80 and 443.

    Instead of using certbot within the Landscape Server LXD container to acquire and configure SSL certificates, you can specify the path of your certificates in variables.txt. Obtain a wildcard subdomain SSL certificate from LetsEncrypt by running:
    
    ```bash
    sudo snap install certbot --classic
    sudo certbot certonly --manual --preferred-challenges dns -d "*.$(grep '^DOMAIN=' variables.txt | cut -d'=' -f2)"
    ```
    
    The following bash commands will update the downloaded cloud-init.yaml file appropriately:

    -  cert.pem: This is the server certificate issued for your domain. It is your primary certificate that identifies your server.

       ```bash
       SSL_CERTIFICATE_PATH=$(grep '^SSL_CERTIFICATE_PATH=' variables.txt | cut -d'=' -f2)
       SSL_CERTIFICATE=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
       sed -i "/# - SSL_CERTIFICATE_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/certs/landscape_server.pem\\n${SSL_CERTIFICATE}\\n    EOF" cloud-init.yaml
       ```

    -  chain.pem: This file contains the intermediate CA certificates needed to establish a chain of trust from your server certificate to the root CA certificate. In many cases, this file is what you need for the CA certificate(s).

       ```bash
       SSL_CERTIFICATE_KEY_PATH=$(grep '^SSL_CERTIFICATE_KEY_PATH=' variables.txt | cut -d'=' -f2)
       SSL_CERTIFICATE_KEY=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_KEY_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
       sed -i "/# - SSL_CERTIFICATE_KEY_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/certs/landscape_server.pem\\n${SSL_CERTIFICATE_KEY}\\n    EOF" cloud-init.yaml
       ```

    - privkey.pem: This is your private key associated with the server certificate. It should be kept secure and private.

      ```bash
      SSL_CERTIFICATE_CHAIN_PATH=$(grep '^SSL_CERTIFICATE_CHAIN_PATH=' variables.txt | cut -d'=' -f2)
      SSL_CERTIFICATE_CHAIN=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_CHAIN_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
      sed -i "/# - SSL_CERTIFICATE_CHAIN_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/certs/landscape_server.pem\\n${SSL_CERTIFICATE_CHAIN}\\n    EOF" cloud-init.yaml
      ```

    -  fullchain.pem: This file includes both your server certificate (cert.pem) and the intermediate CA certificates (chain.pem), providing a complete certificate chain. Since the cert.pem and chain.pem files are independently configured, this file does not need to be used. (It could be used in lieu of cert.pem above, if the SSLCertificateChainFile configurations are commented out in the Apache site configuration.)

4.  Install Landscape Quickstart inside LXD container using cloud-init.yaml:

    > ```bash
    > lxc launch ubuntu:24.04 landscape-example-com --config=user.user-data="$(cat cloud-init.yaml)"
    > ```

---

#### NOTE

The remainder of the steps assume you're using landscape.example.com as the FQDN of your Landscape Server LXD instance. If you decide to use landscape.example.com, you must use the self-signed certificate that is provided upon installation. If you choose to use your own domain name, you have the choice of configuring a valid certificate (recommended), or using the self-signed one.

---

5.  Capture the IP address of the "landscape-example-com" LXD container:

    > ```bash
    > LANDSCAPE_IP=$(lxc list landscape-example-com --format csv -c 4 | awk '{print $1}')
    > ```

6.  Update `/etc/hosts` so other LXD and Multipass Ubuntu instances can resolve `landscape.example.com` to `$LANDSCAPE_IP`

    > ```bash
    > sudo sed -i "/landscape.example.com/d" /etc/hosts
    > echo "$LANDSCAPE_IP landscape.example.com" | sudo tee -a /etc/hosts > /dev/null
    > ```

6.  Configure port forwarding for Port 6554, 443, and 80:

    > ```bash
    > for PORT in 6554 443 80; do lxc config device add landscape-example-com tcp${PORT}proxyv4 proxy listen=tcp:0.0.0.0:${PORT} connect=tcp:${LANDSCAPE_IP}:${PORT}; done
    > ```

7.  Observe progress of the install:

    > ```bash
    > lxc exec landscape-example-com -- bash -c "tail -f /var/log/cloud-init-output.log"
    > ```

8.  When the cloud-init process is complete, you’ll receive two lines similar to this:

    ```text
    cloud-init v. 23.2.2-0ubuntu0~20.04.1 running 'modules:final' at Sun, 20 Aug 2023 17:30:43 +0000. 
    Up 25.14 seconds.
    cloud-init v. 23.2.2-0ubuntu0~20.04.1 finished at Sun, 20 Aug 2023 17:30:56 +0000. Datasource 
    DataSourceGCELocal.  Up 37.35 seconds
    ```

    Press `CTRL`+`C` to terminate the tail process in your terminal window.

9.  Visit `https://landscape.example.com` to finalize configuration.

## Step 2. Configure Landscape

Use Landscape API to configure scripts:

- [TODO] Optional

## Step 3. Create Mirrors

- [TODO] Optional

## Step 4. Snapshots of Landscape Server and Enrolled Instances

[TODO] ./snapshot-take.sh will take a point in time snapshot of Landscape and a selection of LXD and Multipass instances.

[TODO] ./snapshot-restore.sh will restore a point in time snapshot of Landscape and a selection of LXD and Multipass instances.

## Step 5. Enroll Ubuntu instances to Landscape

Edit [./add.sh](add.sh) and update variables on Line 3 through Line 11.

Run [./add.sh](add.sh) to create LXD containers and virtual machines, and Multipass virtual machines, as defined on Lines 34, 35, and 36.

All new instances will be named with a common prefix, to keep things organized. The prefix is in `DAYHHMM` format

## Step 6. Partially patch Ubuntu instances

[TODO] Send `pro fix` commands to each instance during provisioning time to patch vulnerabilities from various points in time.

---

## How to remove

Run [./remove.sh](remove.sh) to delete sets of LXD containers and virtual machines, and Multipass virtual machines. If more than one instance is detected with a `DAYHHMM` prefix, it will be added to a list. Choose which grouping of containers and virtual machines you wish to delete.

Assuming your Landscape installation was named "landscape-example-com", remove it using: `lxc delete --force landscape-example-com`