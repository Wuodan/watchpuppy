#!/usr/bin/env bash

set -e

SCRIPT_NAME=$(basename "$0")  # Get the script's filename

# Set default log level to INFO if LOG_LEVEL is not set
LOG_LEVEL=${LOG_LEVEL:-INFO}

# Log according to LOG_LEVEL
log() {
  local LEVEL=$1
  local MESSAGE=$2

  # Log level precedence mapping
  declare -A LEVELS=( ["DEBUG"]=10 ["INFO"]=20 ["WARNING"]=30 ["ERROR"]=40 ["CRITICAL"]=50 )

  if [ "${LEVELS[$LEVEL]}" -ge "${LEVELS[$LOG_LEVEL]}" ]; then
    echo "$SCRIPT_NAME - $LEVEL - $MESSAGE"
  fi
}

# Check if exactly two arguments are provided
if [ $# -ne 2 ]; then
  log "ERROR" "Usage: $0 /path/to/directory /path/to/process-script"
  exit 1
fi

WATCH_DIR="$1"
PROCESS_SCRIPT="$2"

log "INFO" "Starting file watcher on directory: $WATCH_DIR"
log "INFO" "Process script: $PROCESS_SCRIPT"

# Monitor the directory for new files and react to close_write events
inotifywait -m -r -e close_write --format '%w%f' "$WATCH_DIR" | while read -r NEWFILE
do
  log "INFO" "New file detected: $NEWFILE"

  # Run the process script
  if ! "$PROCESS_SCRIPT" "$NEWFILE"; then
    log "ERROR" "Error executing $PROCESS_SCRIPT with $NEWFILE"
  else
    log "INFO" "Successfully processed $NEWFILE with $PROCESS_SCRIPT"
  fi
done