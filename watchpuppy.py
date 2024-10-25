#!/usr/bin/env python3

# Copyright (c) 2024 Stefan Kuhn
# Licensed under the MIT License

import time
import os
import sys
import logging
from watchdog.observers.polling import PollingObserver as Observer
from watchdog.events import FileSystemEventHandler

# Logging setup
logger = logging.getLogger(os.path.basename(__file__))
logger.setLevel(logging.DEBUG)

log_level = os.getenv("WATCHPUPPY_LOG_LEVEL") or os.getenv("LOG_LEVEL", "INFO")
log_level = log_level.upper()

console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(log_level)
console_handler.setFormatter(logging.Formatter('%(name)s - %(levelname)s - %(message)s'))
logger.addHandler(console_handler)


# Process file when created or modified
class FileHandler(FileSystemEventHandler):
	def __init__(self, process_script):
		self.process_script = process_script

	def on_created(self, event) -> None:
		if not event.is_directory:
			try:
				logger.info("New file detected: %s", event.src_path)
				self.process_file(event.src_path)
			except Exception as e:
				logger.error("Error processing file %s: %s", event.src_path, e)

	def on_modified(self, event):
		if not event.is_directory:
			try:
				logger.info("File modified: %s", event.src_path)
				self.process_file(event.src_path)
			except Exception as e:
				logger.error("Error processing file %s: %s", event.src_path, e)

	def process_file(self, filepath):
		try:
			logger.debug("Running process script: ['%s' '%s']", self.process_script, filepath)
			exit_code = os.system(f"{self.process_script} {filepath}")
			if exit_code != 0:
				raise Exception(
					f"Process script ['{self.process_script}' '{filepath}'] returned non-zero exit code: {exit_code}")
		except Exception as e:
			logger.error("Failed to process %s: %s", filepath, e)


def monitor_directory(watch_dir, process_script):
	event_handler = FileHandler(process_script)
	observer = Observer()
	observer.schedule(event_handler, watch_dir, recursive=True)

	logger.info("Starting file watcher on directory %s with process script %s", watch_dir, process_script)

	observer.start()

	try:
		while True:
			time.sleep(1)
	except KeyboardInterrupt:
		observer.stop()

	observer.join()


if __name__ == "__main__":
	if len(sys.argv) != 3:
		logger.error("Usage: python watch-puppy.py /path/to/directory /path/to/process-script")
		sys.exit(1)

	monitor_directory(watch_dir=sys.argv[1], process_script=sys.argv[2])
