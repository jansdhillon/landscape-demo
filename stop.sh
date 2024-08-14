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
read -r -p "Enter the number of the group to stop: " CHOICE
PREFIX=$(echo "$PREFIXES" | sed -n "${CHOICE}p")

if [ -n "$PREFIX" ]; then
  echo "Stopping instances with prefix: $PREFIX"
  group_instances "$PREFIX" | xargs -I{} lxc stop {}
  for INSTANCE in $(multipass list --format csv | awk -F, '{print $1}' | grep "^$PREFIX"); do
    multipass stop "$INSTANCE"
  done

else
  echo "Invalid choice"
fi
