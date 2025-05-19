# Landscape Demo

Spin up a preconfigured, local Landscape demo. The demo will use `landscape.example.com`, and your system's `/etc/hosts` file will get modified so that you can access the demo at that address.

## Install and configure Landscape Server with Juju


Clone this repository and make `start.sh` executable:

```bash
git clone git@github.com:jansdhillon/ubuntu-instances.git
cd ubuntu-instances
chmod +x start.sh
```

In this demo we will use the Juju, LXD, and yq snaps:

```bash
sudo snap install yq
sudo snap install lxd
sudo snap install juju --classic
```

Initialize LXD:

```bash
sudo usermod -aG lxd "$USER"
newgrp lxd
lxd init --auto
```

Now, create a local LXD cloud with Juju, which will allow us to easily orchestrate the lifecycle of our Landscape system:

```bash
juju bootstrap lxd landscape-controller
```

## Create the Ubuntu instances for Landscape

We need an Ubuntu Pro token to use Landscape, which we can get [here](https://ubuntu.com/pro/dashboard). Save the token value to the `PRO_TOKEN` environment variable:

```bash
export PRO_TOKEN=... # your token here
```

[./start.sh](start.sh) will create Ubuntu instances, starting with Landscape Server and other applications it depends on, followed by Landscape Client instances.

- 💡 **TIP**: Use `juju status --watch 2s` for a live view of the Juju model's lifecycle.

## Tearing Down and Cleaning Up

We can easily clean up our resources with Juju and the following:

```bash
# Get the IPv4 address of our HAProxy Unit
HAPROXY_IP=$(juju show-unit haproxy/0 | yq '."haproxy/0".public-address')
# Remove landscape.example.com entries from /etc/hosts
sudo sed -i "/$HAPROXY_IP[[:space:]]\+landscape.example.com/d" /etc/hosts
# Destroy our controller and model
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
# Remove server cert file
rm server.pem
```
