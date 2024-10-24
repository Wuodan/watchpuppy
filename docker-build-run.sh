#!/usr/bin/env bash

# for debugging
# builds the image and runs a container indefinitely to exec into
# git-bash and docker volumes can be tricky to handle because of path translation

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IMG_NAME=wuodan/watchpuppy:latest
CONTAINER_NAME=watchpuppy

docker build \
  --file Dockerfile \
  -t $IMG_NAME \
  "$SCRIPT_DIR"

echo "Docker image: $IMG_NAME"

# MSYS_NO_PATHCONV prevents path fubar by git-bash on windows
MSYS_NO_PATHCONV=1 docker run -d \
  -v "$SCRIPT_DIR/input/:/data/input:ro" \
  --name "$CONTAINER_NAME" \
  $IMG_NAME \
  tail -f /dev/null

echo "Docker container '$CONTAINER_NAME' running."
echo "Run this for shell access:"
printf '\tdocker exec -it %s bash\n' "$CONTAINER_NAME"
