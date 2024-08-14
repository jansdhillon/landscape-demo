#!/bin/bash

# List all LXC instances in CSV format and extract instance names
INSTANCE_LIST=$(lxc list --format csv | awk -F, '{print $1}' | sort | uniq)

# Function to group instances by common prefix
group_instances() {
  local PREFIX="$1"
  echo "$INSTANCE_LIST" | grep "^$PREFIX" | sort
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
read -r -p "Enter the number of the group to delete: " CHOICE
PREFIX=$(echo "$PREFIXES" | sed -n "${CHOICE}p")

if [ -n "$PREFIX" ]; then
  echo "Deleting instances with prefix: $PREFIX"
  group_instances "$PREFIX" | xargs -I{} lxc delete {} --force

  # Delete all Multipass instances with the same prefix
  MULTIPASS_INSTANCES=$(multipass list --format csv | awk -F, '{print $1}' | grep "^$PREFIX")
  if [ -n "$MULTIPASS_INSTANCES" ]; then
    echo "Deleting Multipass instances with prefix: $PREFIX"
    echo "$MULTIPASS_INSTANCES" | xargs -I{} multipass delete --purge {}
  else
    echo "No Multipass instances found with prefix: $PREFIX"
  fi

else
  echo "Invalid choice"
fi
