Watchpuppy
==========

> Watchpuppy monitors a directory recursively for file changes.

## Purpose

### Problem

Docker environments using mounted file systems from Windows hosts or network file systems lack support for Linux's native, real-time event-driven file monitoring.

### Solution

Watchpuppy leverages [inotifywait](https://github.com/inotify-tools/inotify-tools/wiki#inotifywait) when supported and falls back to polling with [Watchdog](https://github.com/gorakhargosh/watchdog) as needed.

This approach ensures seamless file monitoring, even when the Docker volume's file system type is unknown.

Just add one script, and you're set!


## Installation

Install by one of the following methods.

### Watchpuppy Docker Images

Use the provided Python-based Watchpuppy images as::

- Service in docker-compose.yml
- Base image in Dockerfile

### Download in Dockerfile by curl

Use `curl` in your Dockerfile to download the 2 Watchpuppy scripts.

```dockerfile
## Download files from version 1.0.0
ARG WATCHPUPPY_VERSION="1.0.0"
ARG BASE_URL="https://raw.githubusercontent.com/Wuodan/watchpuppy/${WATCHPUPPY_VERSION}"

## Download both watchpuppy and watchpuppy.py from the specified tag
RUN curl -fsSL "$BASE_URL/watchpuppy" -o watchpuppy \
    && curl -fsSL "$BASE_URL/watchpuppy.py" -o watchpuppy.py
```

For production, verify sha256 checksums of downloaded files in the Dockerfile!

## Example

### docker-compose.yml

With this minimal `docker-compose.yml` Watchpuppy monitors `/data/input` and runs `echo $FILE_PATH` for all file events:

- new file
- file updated or overwritten
- file move
- file delete

```docker-compose.yml
services:
  watchpuppy:
    image: wuodan/watchpuppy
    volumes:
      - ./input/:/data/input:ro
    command: [
      "watchpuppy",
      "--insert-action", "echo",
      "--delete-action", "echo",
      "/data/input"
    ]
```

Start it with:

```shell
$ docker-compose up -d
```

Then add a file to the volume on the host:

```shell
$ touch input/new-file
```

The new file was printed to the docker service logs:

```shell
$ docker-compose logs watchpuppy
watchpuppy-1  | watchpuppy - INFO - Starting file watcher on directory /data/input
watchpuppy-1  | watchpuppy - INFO - Running insert action: ['echo' '/data/input/new-file']
watchpuppy-1  | /data/input/new-file
```

## File Event Actions

| **Event Type**    | **Description**                                   |
|-------------------|---------------------------------------------------|
| File Event        | Movement of a file in the monitored folder tree.  |
| File Event Action | Your custom scripts to further process the event. |

This simple but powerful setup allows a receiving instance to react to all changes of file data.

File event actions are executed for a file event as in:

```shell
my-script.sh "<file-path>"
```

Both `insert-action` and `delete-action` are optional, but at least one must be provided.

## Example For File Event Action Scripts

Instead of `echo` as action, this example uses [sample/action-script.sh](sample/action-script.sh), 
a script that simply prints its own name along with the file it is called with.

```docker-compose.yml
services:
  watchpuppy:
    image: wuodan/watchpuppy
    volumes:
      - ./input/:/data/input:ro
      - ./sample/action-script.sh:/app/bin/insert-action.sh:ro
      - ./sample/action-script.sh:/app/bin/delete-action.sh:ro
    environment:
      WATCHPUPPY_LOG_LEVEL: DEBUG
    command: [
      "watchpuppy",
      "-i", "insert-action.sh",
      "-d", "delete-action.sh",
      "/data/input"
    ]
```

Update the docker-compose project with:

```shell
docker-compose -f sample/docker-compose-better-output.yml -p watchpuppy up -d
```

Wait for restart to finish and delete the file:

```shell
$ rm input/new-file
```

The file delete is again visible in the docker service logs.
And the environment variable `WATCHPUPPY_LOG_LEVEL` increased the log level so we see if `inotifywait` is supported.

```shell
$ docker-compose logs watchpuppy
watchpuppy-1  | watchpuppy - DEBUG - Received these arguments: -i insert-action.sh -d delete-action.sh /data/input
watchpuppy-1  | watchpuppy - DEBUG - File system '9p' of '/data/input' does not support inotifywait. Switching to Python polling.
watchpuppy-1  | watchpuppy - DEBUG - Received these arguments: /app/bin/watchpuppy.py -i insert-action.sh -d delete-action.sh /data/input
watchpuppy-1  | watchpuppy - INFO - Starting file watcher on directory /data/input
watchpuppy-1  | watchpuppy - INFO - Running delete action: ['delete-action.sh' '/data/input/new-file']
watchpuppy-1  | delete-action.sh /data/input/new-file
```

The new configuration also increased the log-level by environment variable `WATCHPUPPY_LOG_LEVEL`.

## Parameters

`watchpuppy` without arguments prints:

```shell
$ ./watchpuppy
Usage: ./watchpuppy [-i|--insert-action <INSERT_ACTION>] [-d|--delete-action <DELETE_ACTION>] [--sync] <directory_path>
At least one of -i or -d must be specified.
```

### Async / sync

By default, Watchpuppy executes actions asynchronously in a fire-and-forget mode.

With the `--sync` parameter, actions are executed synchronously, allowing their results to be logged by Watchpuppy.
> **Note**: `--sync` is a beta feature and may not be fully stable.

## ENV Variables

### Log Levels

The log level can be set using the environment variable `WATCHPUPPY_LOG_LEVEL`.
If `WATCHPUPPY_LOG_LEVEL` is not provided, the script will fall back to the value of `LOG_LEVEL` (if set). The log level
can be one of the following:

- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`
- `CRITICAL`

If neither `WATCHPUPPY_LOG_LEVEL` nor `LOG_LEVEL` is set, the default level is `INFO`.
