# Landscape Demo

You need the Multipass and LXD snap packages to be installed on your Linux machine to run a local Landscape demo. You need the landscape-api snap package installed to perform headless Landscape configurations, without interacting with the Landscape GUI.

## Deploy Landscape

Deploy to LXD container using: [TODO]

## Configure Landscape

Use Landscape API to configure:

- Scripts [TODO]

## Create Mirrors

[TODO]

## Snapshots of Landscape Server and Enrolled Instances

[TODO] ./snapshot-take.sh will take a point in time snapshot of Landscape and a selection of LXD and Multipass instances.

[TODO] ./snapshot-restore.sh will restore a point in time snapshot of Landscape and a selection of LXD and Multipass instances.

## Enroll Ubuntu instances to Landscape

Edit [./add.sh](add.sh) and update variables on Line 3 through Line 11.

Run [./add.sh](add.sh) to create LXD containers and virtual machines, and Multipass virtual machines, as defined on Lines 34, 35, and 36.

All new instances will be named with a common prefix, to keep things organized. The prefix is in `DAYHHMM` format

## Partially patch Ubuntu instances

### Method 1: Using `pro fix`

This method assumes Internet connectivity

### Method 2: Using local mirrors

This method requires time for Landscape Client to apply repository configurations.

## Remove Ubuntu instances

Run [./remove.sh](remove.sh) to delete sets of LXD containers and virtual machines, and Multipass virtual machines. If more than one instance is detected with a `DAYHHMM` prefix, it will be added to a list. Choose which grouping of containers and virtual machines you wish to delete.