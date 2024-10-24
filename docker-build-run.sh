#!/usr/bin/env bash

# for debugging
# builds the image and runs a container indefinitely to exec into
# git-bash and docker volumes can be tricky to handle because of path translation

# Enable exit on error
set -e

# print shell commands in this script
# set -o xtrace

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Loading environment variables from .env file..."
source .env

docker container rm -f "$CONTAINER_NAME" || true

docker build \
  --rm \
  --file "$SCRIPT_DIR/Dockerfile" \
  -t "$IMG_NAME" \
  "$SCRIPT_DIR"

echo "Docker image: $IMG_NAME"

# MSYS_NO_PATHCONV prevents path fubar by git-bash on windows
MSYS_NO_PATHCONV=1 docker run -d \
  -v "$SCRIPT_DIR/input/:/data/input:ro" \
  --name "$CONTAINER_NAME" \
  "$IMG_NAME" \
  tail -f /dev/null

echo "Docker container '$CONTAINER_NAME' running, but your app is not !"
echo
echo "For a shell in the container run:"
echo
printf "\tOn Windows in git-bash:\n"
printf '\t\twinpty docker exec -it %s bash\n' "$CONTAINER_NAME"
echo
printf "\tOn Linux:\n"
printf '\tdocker exec -it %s bash\n' "$CONTAINER_NAME"
echo
echo "from there you can start your app/script or debug something."
echo
echo
echo "Trying to determine terminal type and to give you shell access now ..."

EXEC_CMD=("docker" "exec" "-it" "watchpuppy" "bash")

# Disable exit on error
set +e
# Try running docker exec without winpty first
"${EXEC_CMD[@]}"
EXIT_CODE=$?

# Enable exit on error
set -e

# Check if the previous command failed (non-zero exit code)
if [[ $EXIT_CODE -ne 0 ]]; then
    echo
    echo "'docker exec' failed - you might be on Windows."
    echo "Trying again with 'winpty docker exec'..."
    WINPTY_EXEC_CMD=("winpty" "${EXEC_CMD[@]}")
    "${WINPTY_EXEC_CMD[@]}"
fi