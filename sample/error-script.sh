#!/usr/bin/env sh

set -e

# Get the name of the script or symlink name
SCRIPT_NAME=$(basename "$0")

# print error to STDERR
echo "ERROR - $SCRIPT_NAME $*" 2>&1

# Exit with error
exit 1