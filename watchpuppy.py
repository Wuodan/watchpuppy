#!/usr/bin/env python3
"""
WatchPuppy - A file monitoring tool that watches a directory for file changes and triggers
specific actions.

This script utilizes the `watchdog` library to detect filesystem events such as file creation,
It takes optional scripts as arguments for handling 'insert' and 'delete' actions on detected files.
The `--sync` option can be used to run the scripts synchronously and report any crashes.

Usage:
    python watchpuppy.py <directory_path> [--insert-action <INSERT_ACTION>] [--delete-action
    <DELETE_ACTION>] [--sync]
"""

import os
import sys
import time
import logging
import argparse
import subprocess
from typing import Optional
from watchdog.observers.polling import PollingObserver as Observer
from watchdog.events import FileSystemEventHandler

# Logging setup
logger = logging.getLogger("watchpuppy")
log_level = os.getenv("WATCHPUPPY_LOG_LEVEL", os.getenv("LOG_LEVEL", "INFO")).upper()
logger.setLevel(log_level)

console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(log_level)
console_handler.setFormatter(logging.Formatter('%(name)s - %(levelname)s - %(message)s'))
logger.addHandler(console_handler)


class FileHandler(FileSystemEventHandler):
    """
    Handles file system events by executing specified scripts for insert and delete actions.

    Attributes:
        insert_script (Optional[str]): The script to run when a file is created or modified.
        delete_script (Optional[str]): The script to run when a file is deleted.
        sync (bool): Whether to execute scripts synchronously.
    """

    def __init__(self, insert_script: Optional[str] = None, delete_script: Optional[str] = None,
                 sync_mode: bool = False) -> None:
        self.insert_script = insert_script
        self.delete_script = delete_script
        self.sync = sync_mode

    def on_any_event(self, event) -> None:
        """
        Triggers on any file system event and determines the appropriate action.

        Args:
            event: The file system event triggering this handler.
        """
        if not event.is_directory:
            file_path = event.src_path if event.event_type != "moved" else event.dest_path
            self.handle_event(event_type=event.event_type, file_path=file_path)

    def handle_event(self, event_type: str, file_path: str) -> None:
        """
        Determines the type of event and executes the appropriate script.

        Args:
            event_type (str): The type of file system event (e.g., created, modified, deleted).
            file_path (str): Path of the file related to the event.
        """
        if self.insert_script and event_type in ('created', 'moved', 'modified'):
            logger.info("Running insert action: ['%s' '%s']", self.insert_script, file_path)
            self.run_action(script=self.insert_script, file_path=file_path)
        elif self.delete_script and event_type in ('deleted', 'moved_from'):
            logger.info("Running delete action: ['%s' '%s']", self.delete_script, file_path)
            self.run_action(script=self.delete_script, file_path=file_path)

    def run_action(self, script: str, file_path: str) -> None:
        """
        Executes the specified script on the file path, handling errors as needed.

        Args:
            script (str): Path to the script to execute.
            file_path (str): Path of the file to pass to the script.
        """
        try:
            if self.sync:
                # Synchronous mode, raising error if the script fails
                subprocess.run([script, file_path], check=True, text=True)
                logger.info("Script completed successfully: %s %s", script, file_path)
            else:
                # Asynchronous mode
                subprocess.Popen([script, file_path], text=True) # pylint: disable=consider-using-with
        except subprocess.CalledProcessError as e:
            logger.error("Script [%s %s] failed with exit code %d: %s",
                         script, file_path, e.returncode, e.stderr)
        except OSError as e:
            logger.error("Failed to execute script [%s] on file [%s]: %s", script, file_path, e)


def monitor_directory(watch_dir: str,
                      insert_script: Optional[str],
                      delete_script: Optional[str],
                      sync_mode: bool) -> None:
    """
    Monitors a directory for file events and executes corresponding actions.

    This function initializes a file event handler for the specified `watch_dir`, observing for
    file
    creation, modification, and deletion events. Depending on the event type, it triggers the
    `insert_script` or `delete_script` as specified. The `sync_mode` flag determines whether
    scripts execute synchronously or asynchronously.

    Args:
        watch_dir (str): Path to the directory to monitor for file events.
        insert_script (Optional[str]): Path to the script to run for insert actions (
        creation/modification).
        delete_script (Optional[str]): Path to the script to run for delete actions.
        sync_mode (bool): If True, runs scripts synchronously; otherwise, runs them asynchronously.

    Returns:
        None
    """
    event_handler = FileHandler(insert_script=insert_script, delete_script=delete_script,
                                sync_mode=sync_mode)
    observer = Observer()
    observer.schedule(event_handler, watch_dir, recursive=True)

    logger.info("Starting file watcher on directory %s", watch_dir)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()


if __name__ == "__main__":
    # debug dump arguments
    logger.debug("Received these arguments: %s", " ".join(sys.argv))

    parser = argparse.ArgumentParser(
        description="Watch a directory and handle file events with specified actions.")
    parser.add_argument("-i", "--insert-action", type=str,
                        help="Path to the insert action script")
    parser.add_argument("-d", "--delete-action", type=str,
                        help="Path to the delete action script")
    parser.add_argument("--sync", action="store_true",
                        help="Wait for script completion and report crashes")
    parser.add_argument("directory_path", type=str,
                        help="Path to the directory to watch")

    args = parser.parse_args()

    # Validate directory path
    if not os.path.isdir(args.directory_path):
        logger.error("The specified directory does not exist: %s", args.directory_path)
        sys.exit(1)

    # Ensure at least one action script is provided
    if not (args.insert_action or args.delete_action):
        logger.error("At least one of --insert-action or --delete-action must be specified.")
        sys.exit(1)

    # Start monitoring with provided scripts and sync mode
    monitor_directory(
        watch_dir=args.directory_path,
        insert_script=args.insert_action,
        delete_script=args.delete_action,
        sync_mode=args.sync
    )
