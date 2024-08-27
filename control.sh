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
  echo "$1" | grep -- "-lds-"
}

# Function to update /etc/hosts with Landscape FQDN and IP
update_hosts_file() {
  local ACTION="$1" # either "add" or "remove"
  local PREFIX="$2"
  local INSTANCE
  local LANDSCAPE_IP
  local LANDSCAPE_FQDN
  INSTANCE=$(find_lds "$PREFIX")
  if [ -n "$INSTANCE" ]; then
    if [ "$ACTION" = "add" ]; then
      LANDSCAPE_IP=$(lxc info "$INSTANCE" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1)
      LANDSCAPE_FQDN=$(lxc exec "$INSTANCE" -- hostname)
      if [ -n "$LANDSCAPE_FQDN" ]; then
        echo "$ACTION $LANDSCAPE_FQDN to $(hostname)'s /etc/hosts"
        sudo -v
        sudo bash -c "echo \"$LANDSCAPE_IP $LANDSCAPE_FQDN\" >> /etc/hosts"
        sudo -k
      else
        echo "Error: LANDSCAPE_FQDN is empty. Aborting changes to /etc/hosts."
      fi
    elif [ "$ACTION" = "remove" ]; then
      LANDSCAPE_FQDN=$(lxc exec "$INSTANCE" -- hostname)
      echo "$ACTION $LANDSCAPE_FQDN to $(hostname)'s /etc/hosts"
      sudo -v
      sudo sed -i "/$LANDSCAPE_FQDN/d" /etc/hosts
      sudo -k
    fi
  fi
}

# Function to start or stop a single instance
manage_instance() {
  local ACTION="$1" # either "start" or "stop"
  local INSTANCE="$2"
  echo "lxc $ACTION $INSTANCE"
  if [ "$ACTION" = "start" ]; then
    lxc start "$INSTANCE"
    until lxc info "$INSTANCE" | grep -q 'Status: RUNNING'; do
      sleep 1
    done
    update_hosts_file "add" "$INSTANCE"
  elif [ "$ACTION" = "stop" ]; then
    output=$(lxc exec "$INSTANCE" -- hostname)
    if ! echo "$output" | grep -q '^Error:'; then
      update_hosts_file "remove" "$INSTANCE"
    fi
    lxc stop "$INSTANCE"
  fi
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
read -r -p "Enter the number of the group to manage: " CHOICE
PREFIX=$(echo "$PREFIXES" | sed -n "${CHOICE}p")

# Prompt user to choose 1 for start or 2 for stop
read -r -p "Would you like to start or stop the instances?
1 to start
2 to stop

Enter your choice (1 or 2): " ACTION

if [[ "$ACTION" != "1" && "$ACTION" != "2" ]]; then
  echo "Invalid choice. Please enter '1' for start or '2' for stop."
  exit 1
fi

# Convert numerical input to corresponding action
if [[ "$ACTION" == "1" ]]; then
  ACTION="start"
elif [[ "$ACTION" == "2" ]]; then
  ACTION="stop"
fi

# Now, ACTION is either "start" or "stop"
echo "You chose to $ACTION the instances."

if [ -n "$PREFIX" ]; then
  echo "${ACTION^} instances with prefix: $PREFIX"

  # Manage LXC instances
  group_instances "$PREFIX" | while read -r INSTANCE; do
    manage_instance "$ACTION" "$INSTANCE"
  done

  # Manage Multipass instances
  for INSTANCE in $(multipass list --format csv | awk -F, '{print $1}' | grep "^$PREFIX"); do
    echo "multipass ""$ACTION"" ""$INSTANCE"""
    multipass "$ACTION" "$INSTANCE"
  done
else
  echo "Invalid choice"
fi
