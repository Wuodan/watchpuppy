#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# SLEUTHKIT_VERSION=sleuthkit-4.12.1
SLEUTHKIT_VERSION=ff3c3c7fb68394a4406e275b578b5345ee54a708

IMG_NAME=sleuthkit:${SLEUTHKIT_VERSION}
CONTAINER_NAME=sleuthkit-${SLEUTHKIT_VERSION}

docker build \
  --file Dockerfile \
  --build-arg SLEUTHKIT_VERSION=$SLEUTHKIT_VERSION \
  -t $IMG_NAME \
  "$SCRIPT_DIR"

echo "Docker image: $IMG_NAME"

# MSYS_NO_PATHCONV prevents path fubar by git-bash on windows
MSYS_NO_PATHCONV=1 docker run -d \
  -v "$SCRIPT_DIR/input/:/data/input:ro" \
  -v "$SCRIPT_DIR/output/:/data/output:rw" \
  -v "$SCRIPT_DIR/sleuthkit_script.py:/data/sleuthkit_script.py:ro" \
  --name "$CONTAINER_NAME" \
  $IMG_NAME \
  tail -f /dev/null

echo "Docker container '$CONTAINER_NAME' running"