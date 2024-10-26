#!/usr/bin/env sh

set -e

# Get the name of the script or symlink name
SCRIPT_NAME=$(basename "$0")

# Print the script name and all parameters
echo "$SCRIPT_NAME $*"