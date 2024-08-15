#!/bin/bash

# List all LXC instances in CSV format and extract instance names
INSTANCE_LIST=$(lxc list --format csv | awk -F, '{print $1}' | sort | uniq)

# Function to group instances by common prefix
group_instances() {
  local PREFIX="$1"
  echo "$INSTANCE_LIST" | grep "^$PREFIX" | sort
}

# Function to find the Landscape LXD instance using the "-lds-" prefix
find_lds() {
  local PREFIX="$1-lds-"
  echo "$INSTANCE_LIST" | grep "^$PREFIX"
}

# Generate a list of prefixes that are shared by more than one instance
PREFIXES=$(echo "$INSTANCE_LIST" | sed 's/-.*//' | sort | uniq -c | awk '$1 > 1 {print $2}')

# Check if there are any valid prefixes
if [ -z "$PREFIXES" ]; then
  echo "Multiple instances with common prefixes not found."
  exit 1
fi

# List available prefixes
echo "Available prefixes with more than one instance:"
I=1
for PREFIX in $PREFIXES; do
  echo "$I. $PREFIX"
  I=$((I + 1))
done

# Prompt user to select a prefix group
read -r -p "Enter the number of the group to start: " CHOICE
PREFIX=$(echo "$PREFIXES" | sed -n "${CHOICE}p")

if [ -n "$PREFIX" ]; then
  echo "Starting instances with prefix: $PREFIX"
  INSTANCE_NAME=$(find_lds "$PREFIX")
  if [ -n "$INSTANCE_NAME" ]; then
    lxc start $INSTANCE_NAME --verbose
    LANDSCAPE_FQDN=$(find_lds "$PREFIX" | xargs -I{} lxc exec {} -- hostname --long)
    if [ -n "$LANDSCAPE_FQDN" ]; then
      sudo sed -i "/$LANDSCAPE_FQDN/d" /etc/hosts
    else
      echo "Error: LANDSCAPE_FQDN is empty. Aborting changes to /etc/hosts."
    fi
  fi
  LANDSCAPE_IP=$(lxc info "$INSTANCE_NAME" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1)
  echo "$LANDSCAPE_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts > /dev/null
  group_instances "$PREFIX" | xargs -I{} lxc start {}
  for INSTANCE in $(multipass list --format csv | awk -F, '{print $1}' | grep "^$PREFIX"); do
    multipass start "$INSTANCE" --verbose
  done

else
  echo "Invalid choice"
fi
