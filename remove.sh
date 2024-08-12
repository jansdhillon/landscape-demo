#!/bin/bash

# List all LXC instances in CSV format and extract instance names
instance_list=$(lxc list --format csv | awk -F, '{print $1}' | sort | uniq)

# Function to group instances by common prefix
group_instances() {
  local prefix="$1"
  echo "$instance_list" | grep "^$prefix" | sort
}

# Generate a list of prefixes that are shared by more than one instance
prefixes=$(echo "$instance_list" | sed 's/-.*//' | sort | uniq -c | awk '$1 > 1 {print $2}')

# Check if there are any valid prefixes
if [ -z "$prefixes" ]; then
  echo "Multiple instances with common prefixes not found."
  exit 1
fi

# List available prefixes
echo "Available prefixes with more than one instance:"
i=1
for prefix in $prefixes; do
  echo "$i. $prefix"
  i=$((i + 1))
done

# Prompt user to select a prefix group
read -r -p "Enter the number of the group to delete: " choice
prefix=$(echo "$prefixes" | sed -n "${choice}p")

if [ -n "$prefix" ]; then
  echo "Deleting instances with prefix: $prefix"
  group_instances "$prefix" | xargs -I{} lxc delete {} --force

  # Delete all Multipass instances with the same prefix
  multipass_instances=$(multipass list --format csv | awk -F, '{print $1}' | grep "^$prefix")
  if [ -n "$multipass_instances" ]; then
    echo "Deleting Multipass instances with prefix: $prefix"
    echo "$multipass_instances" | xargs -I{} multipass delete --purge {}
  else
    echo "No Multipass instances found with prefix: $prefix"
  fi

else
  echo "Invalid choice"
fi