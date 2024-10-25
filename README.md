Watchpuppy
==========

> Watchpuppy is built on top of [Watchdog](https://github.com/gorakhargosh/watchdog) and [inotifywait](https://github.com/inotify-tools/inotify-tools/wiki#inotifywait)


WatchPuppy combines  inotify and Python polling for a seamless cross-platform file monitoring solution, 
dynamically adapting to the monitoring capabilities of shared folders and their file systems in Docker containers, 
supporting both Linux and Windows hosts.


## Purpose

### Problem
In Docker environments, monitoring file changes on shared or mounted volumes can be challenging. The native Linux `inotify` mechanism provides efficient, event-driven file monitoring, but many shared file systems (such as network file systems or those mounted from Windows hosts) do not support `inotify`. This limitation means that real-time file event notifications are unavailable on those file systems.

### Solution
Watchpuppy automatically checks the file system type of the target directory to determine if `inotify` can be used. If `inotify` is supported, Watchpuppy uses `inotifywait` for efficient, real-time monitoring. If `inotify` isn’t available, it falls back to polling with Python’s `watchdog` library, which periodically checks for file changes.

While polling provides broad compatibility, it is not as efficient or reliable as event-driven monitoring and may miss rapid or transient changes. Despite these limitations, the fallback to polling allows to support consistent file monitoring across various host and file system types without additional configuration.

## Example Setup with Docker Compose

The `docker-compose.yml` configuration shows how Watchpuppy monitors file changes across shared and internal directories in Docker containers, even when mounted from different host environments like Windows.

### Services

1. **Alpine-Based Watchpuppy Service** (`watchpuppy-alpine`)
   - Monitors a host-mounted folder (`./input/`) mapped to `/data/input` as **read-only**.
   - Watchpuppy automatically selects the best monitoring method based on the mounted file system’s capabilities.
   - Log level: `WARN` for concise output by environment variable `WATCHPUPPY_LOG_LEVEL`.

2. **Debian-Based Watchpuppy Service** (`watchpuppy-debian`)
   - Monitors the `./input/` folder (mapped to `/data/input` as **read-only**) for file insert events.
   - Log level: Not set, uses default `INFO` for general output.

3. **Demo Service** (`watchpuppy-demo`)
   - Has the `./input/` folder mounted as **writable** at `/data/input`, allowing it to insert files and demonstrate insert-event detection.
   - Also monitors an internal folder, `/home/appuser/demo-dir`, to showcase inotify-based monitoring on a standard Linux file system.
   - Log level: `DEBUG` for detailed output.
   - Inserts files into both `/data/input` and `/home/appuser/demo-dir`:
      - Insertions into `/data/input` demonstrate monitoring on a shared, host-mounted directory.
      - Insertions into `/home/appuser/demo-dir` demonstrate inotify-based monitoring on an internal directory.

### Summary

This setup demonstrates:
- **Cross-platform compatibility**: Watchpuppy monitors files on shared volumes from various host environments, such as Windows hosts with Linux containers.
- **Flexible monitoring**: Adapts to both inotify-compatible and incompatible file systems, using polling when necessary.
- **Comprehensive file event detection**: Supports both shared and internal directories in Docker.
- **Configuration for different Linux distributions**: The Dockerfile shows configuration differences for Alpine and Debian-based images.

## Log Levels

The log level can be set using the environment variable `WATCHPUPPY_LOG_LEVEL`.
If `WATCHPUPPY_LOG_LEVEL` is not provided, the script will fall back to the value of `LOG_LEVEL` (if set). The log level can be one of the following:

- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`
- `CRITICAL`

If neither `WATCHPUPPY_LOG_LEVEL` nor `LOG_LEVEL` is set, the default level is `INFO`.

