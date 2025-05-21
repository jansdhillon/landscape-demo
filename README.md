# Landscape Demo

Spin up a preconfigured, local Landscape demo. The demo will use `landscape.example.com`, and your system's `/etc/hosts` file will get modified so that you can access the demo at that address.

## Install and configure Landscape Server with Juju


Clone this repository and make `run.sh` executable:

```bash
git clone git@github.com:jansdhillon/landscape-demo.git
cd landscape-demo
chmod +x run.sh
```

In this demo we will use the Juju, LXD, and yq snaps. Install
them if you have not already:

```bash
sudo snap install yq
sudo snap install lxd
sudo snap install juju --classic
```

- 💡 **TIP**: Make sure LXD has been initialized before proceeding. You should see `lxd` when running `groups`, otherwise see [the LXD documentation](https://documentation.ubuntu.com/lxd) to get set up.


## Create the Ubuntu instances for Landscape

We need an Ubuntu Pro token to use Landscape, which we can get [here](https://ubuntu.com/pro/dashboard). Save the token value to the `PRO_TOKEN` environment variable:

```bash
export PRO_TOKEN=... # your token here
```

[./run.sh](run.sh) will create Ubuntu instances to run Landscape, starting with Landscape Server and other applications it depends on, followed by Landscape Client instances that are managed by Landscape Server.

## Logging in 

The first administrator account is created for you, and the credentials are as follows:

- Email: `admin@example.com`
- Password: `pwd`

## Script Execution

[./run.sh](run.sh) created a script and a script profile for it, which makes it execute on the Landscape Client instance on a set interval:

```bash
#!/bin/bash
echo "Hello world!" | tee hello.txt'
```

Additionally, in the [Activities tab](https://landscape.example.com/new_dashboard/activities), you can see that it was already (or set to be) manually executed on the Landscape Client instance.

After the script has finished running, we can verify the script ran by SSH'ing into the Landscape Client unit:

```bash
juju ssh root@landscape-client/0 "sudo cat hello.txt" # scripts are run as root so we must use sudo to see the file
# Hello world!
```

## Tearing Down and Cleaning Up

We can easily clean up our resources with Juju and the following:

```bash
# Get the IPv4 address of our HAProxy Unit
HAPROXY_IP=$(juju show-unit haproxy/0 | yq '."haproxy/0".public-address')
# Remove landscape.example.com entries from /etc/hosts
if [ -n "${HAPROXY_IP}" ]; then
    printf "Modifying /etc/hosts requires elevated privileges.\n"
    sudo sed -i "/${HAPROXY_IP}[[:space:]]\\+landscape\.example\.com/d" /etc/hosts
fi
# Destroy the controller and model for Landscape
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
```
