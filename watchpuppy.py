#!/usr/bin/env python3

import time
import os
import sys
import logging
from watchdog.observers.polling import PollingObserver as Observer
from watchdog.events import FileSystemEventHandler

# Logging setup
logger = logging.getLogger(os.path.basename(__file__))
logger.setLevel(logging.DEBUG)

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(log_level)
console_handler.setFormatter(logging.Formatter('%(name)s - %(levelname)s - %(message)s'))
logger.addHandler(console_handler)


# Process file when created or modified
class FileHandler(FileSystemEventHandler):
	def __init__(self, process_script):
		self.process_script = process_script

	def on_created(self, event):
		if not event.is_directory:
			try:
				logger.info(f"New file detected: {event.src_path}")
				self.process_file(event.src_path)
			except Exception as e:
				logger.error(f"Error processing file {event.src_path}: {e}")

	def on_modified(self, event):
		if not event.is_directory:
			try:
				logger.info(f"File modified: {event.src_path}")
				self.process_file(event.src_path)
			except Exception as e:
				logger.error(f"Error processing file {event.src_path}: {e}")

	def process_file(self, filepath):
		try:
			logger.info(f"Running process script on: {filepath}")
			exit_code = os.system(f"{self.process_script} {filepath}")
			if exit_code != 0:
				raise Exception(f"Process script returned non-zero exit code: {exit_code}")
		except Exception as e:
			logger.error(f"Failed to process {filepath}: {e}")


def monitor_directory(watch_dir, process_script):
	event_handler = FileHandler(process_script)
	observer = Observer()
	observer.schedule(event_handler, watch_dir, recursive=True)

	logger.info(f"Starting file watcher on directory: {watch_dir}")
	logger.info(f"Process script: {process_script}")

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
