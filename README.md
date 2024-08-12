# Landscape Demo

You need the Multipass, LXD, and yq snap packages to be installed on your Linux machine to run a local Landscape demo. Optionally, you need the landscape-api snap package installed to perform headless Landscape configurations, without interacting with the Landscape GUI.

## Step 1. Deploy Landscape

Deploy to LXD container using cloud-init.yaml: https://ubuntu.com/landscape/docs/install-in-a-lxd-container

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