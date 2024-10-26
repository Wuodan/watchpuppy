#!/usr/bin/env sh

# used to run tests inside docker containers

set -e

test_run() {
  # cd to watched-dir
  cd "$1"
  # new file
  touch new-file
  # wait so polling sees change
  sleep 3
  # move the file inside watched-dir
  mv new-file moved-file
  sleep 3
  # delete file
  rm moved-file
  sleep 3
  # create file outside watched-dir
  touch ~/a-file
  # move to watched-dir
  mv ~/a-file .
  sleep 3
  # move from watched-dir
  mv a-file ~
}

# run-test in shared folder with Python polling (if host is Windows)
# triggers only other services watchpuppy and watchpuppy-error
test_run /data/input

# everything below tests where inotify is surely supported: Inside this service

# mkdir where inotifywait support is present for sure
mkdir -p /home/appuser/success-dir
mkdir -p /home/appuser/error-dir

# setup inotify success
watchpuppy \
  --insert-action insert-action.sh \
  --delete-action delete-action.sh \
  /home/appuser/success-dir \
  &

# wait for inotifywait setup
# 5 seconds is usually enough
sleep 5

# test inotify success
test_run /home/appuser/success-dir

# sleep for debug log-check
sleep 5

# setup inotify error
watchpuppy \
  --insert-action insert-error.sh \
  --delete-action delete-error.sh \
  /home/appuser/error-dir \
  &

# wait for inotifywait setup
sleep 5

# test inotify error
test_run /home/appuser/error-dir

# keep container running
tail -f /dev/null