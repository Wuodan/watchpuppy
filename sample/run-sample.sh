#!/usr/bin/env sh

# runs the docker-compose-test.yml in this folder
# provides placeholders for variables to test with them

set -e

# Get the path to the actual script, resolving any symlinks
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# start with parameters to play with and test

# alpine or debian
WATCHPUPPY_TAG="${WATCHPUPPY_TAG:-}" \
# use this ARG for debian tag
# BASE_IMAGE: python:3-slim-bookworm \
# python log levels: DEBUG INFO WARNING (WARN) ERROR CRITICAL
WATCHPUPPY_LOG_LEVEL="${WATCHPUPPY_LOG_LEVEL:-}" \
LOG_LEVEL="${LOG_LEVEL:-}" \
# now docker-compose
docker-compose \
    -p watchpuppy-sample \
    -f "$SCRIPT_DIR"/docker-compose-test.yml \
    up -d