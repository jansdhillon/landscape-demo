## Landscape Demo

You need the Multipass and LXD snap packages to be installed on your Linux machine to run a local Landscape demo. You need the landscape-api snap package installed to perform headless Landscape configurations, without interacting with the Landscape GUI.

### Deploy Landscape

Deploy to LXD container using: [TODO]

### Configure Landscape

Use Landscape API to configure:

- Scripts
- 

### Create Mirrors

[TODO]

### Enroll Ubuntu instances to Landscape

Edit [./add.sh](add.sh) and update variables on Line 3 through Line 11.

Run [./add.sh](add.sh) to create LXD containers and virtual machines, and Multipass virtual machines, as defined on Lines 34, 35, and 36.

All new instances will be named with a common prefix, to keep things organized. The prefix is in `DAYHHMM` format

### Partially patch Ubuntu instances

#### Method 1: Using `pro fix`

This method assumes Internet connectivity

#### Method 2: Using local mirrors

This method requires time for Landscape Client to apply repository configurations.

### Remove Ubuntu instances

Run [./remove.sh](remove.sh) to delete sets of LXD containers and virtual machines, and Multipass virtual machines. If more than one instance is detected with a `DAYHHMM` prefix, it will be added to a list. Choose which grouping of containers and virtual machines you wish to delete.

### Known Issues

Ubuntu Core VMs are unable to enroll with Landscape. To reproduce this issue without silent output, attempt the following in your CLI:

```bash
landscape_fqdn="landscapedemo.rajanpatel.com"
landscape_account_name="standalone"
http_proxy=""
https_proxy=""
script_users="ALL"
tags=""
access_group="global"
registration_key=""
multipass launch core24 -n my-core-vm
multipass exec my-core-vm -- sudo snap refresh
multipass exec my-core-vm -- sudo snap install landscape-client
echo -n | openssl s_client -connect $landscape_fqdn:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | multipass transfer --parents - my-core-vm:/home/ubuntu/certs/landscape.pem
multipass exec my-core-vm -- sudo landscape-client.config --account-name="$landscape_account_name" --computer-title="\$(hostname --long)" --url "https://$landscape_fqdn/message-system" --ping-url "http://$landscape_fqdn/ping" --ssl-public-key=/home/ubuntu/certs/landscape.pem --tags="$tags" --script-users="$script_users" --http-proxy="$http_proxy" --https-proxy="$https_proxy" --access-group="$access_group" --registration-key="$registration_key"
```

Output:
```text
Manage this machine with Landscape (https://ubuntu.com/landscape):


A summary of the provided information:
Computer's Title: $(hostname --long)
Account Name: standalone
Landscape FQDN: landscapedemo.rajanpatel.com
Registration Key: False


The landscape config parameters to repeat this registration on another machine are:


sudo landscape-client.config --account-name standalone --url https://landscapedemo.rajanpatel.com/message-system --ping-url http://landscapedemo.rajanpatel.com/ping


Request a new registration for this computer now? [y/N]: y

We were unable to contact the server.
Your internet connection may be down. The landscape client will continue to try and contact the server periodically.
```