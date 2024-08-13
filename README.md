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

2.  Create a variables.txt file with the following contents. Change variables values where appropriate.

    ```text
    EMAIL=rajan.patel@canonical.com
    TOKEN=REDACTED
    HOSTNAME=landscape
    DOMAIN=example.com
    TIMEZONE=America/New_York
    SMTP_HOST=smtp.sendgrid.net
    SMTP_PORT=587
    SMTP_USERNAME=apikey
    SMTP_PASSWORD=REDACTED
    LANDSCAPE_VERSION=24.04
    ```

3.  Update cloud-init.yaml with the contents of variables.txt

    > ```bash
    > while IFS='=' read -r key value; do sed -i "s|{% set $key = '.*' %}|{% set $key = '$value' %}|" cloud-init.yaml; done < variables.txt
    > ```

4.  Install Landscape Quickstart inside LXD container using cloud-init.yaml:

    > ```bash
    > lxc launch ubuntu:24.04 landscapedemo --config=user.user-data="$(cat cloud-init.yaml)" 
    > ```

5.  Capture the IP address of the "landscapedemo" LXD container:

    > ```bash
    > LANDSCAPE_IP=$(lxc list landscapedemo --format csv -c 4 | awk '{print $1}')
    > ```

6.  Configure port forwarding for Port 6554, 443, and 80:

    > ```bash
    > for PORT in 6554 443 80; do lxc config device add landscapedemo tcp${PORT}proxyv4 proxy listen=tcp:0.0.0.0:${PORT} connect=tcp:${LANDSCAPE_IP}:${PORT}; done
    > ```

7.  Observe progress of the install:

    > ```bash
    > lxc exec landscapedemo -- bash -c "tail -f /var/log/cloud-init-output.log"
    > ```

8.  When the cloud-init process is complete, you’ll receive two lines similar to this:

    ```text
    cloud-init v. 23.2.2-0ubuntu0~20.04.1 running 'modules:final' at Sun, 20 Aug 2023 17:30:43 +0000. 
    Up 25.14 seconds.
    cloud-init v. 23.2.2-0ubuntu0~20.04.1 finished at Sun, 20 Aug 2023 17:30:56 +0000. Datasource 
    DataSourceGCELocal.  Up 37.35 seconds
    ```

    Press `CTRL`+`C` to terminate the tail process in your terminal window.

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

Assuming your Landscape installation was named "landscapedemo", remove it using: `lxc delete --force landscapedemo`