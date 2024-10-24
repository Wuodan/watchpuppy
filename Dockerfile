# Base image argument
ARG BASE_IMAGE=python:3-alpine

FROM ${BASE_IMAGE}

# For logging
ENV LOG_LEVEL=INFO

# Install inotify-tools
RUN \
    if command -v apk > /dev/null 2>&1; then \
        # For Alpine
        apk add --no-cache inotify-tools coreutils; \
    elif command -v apt-get > /dev/null 2>&1; then \
        # For Debian
        apt-get update && \
        apt-get install -y --no-install-recommends inotify-tools && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Unsupported package manager. Exiting." && \
        exit 1; \
    fi

# Create a non-privileged user that the app will run under.
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Switch to the non-privileged user to setup venv
USER appuser

WORKDIR /app

# Create a virtual environment
RUN python3 -m venv venv
# Ensure the virtual environment is used for all future commands
ENV PATH="/app/venv/bin:$PATH"

# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=bind,source=requirements.txt,target=requirements.txt,readonly \
    python3 -m pip install --upgrade pip \
    && python3 -m pip install -r requirements.txt \
    && rm -rf /tmp/* /home/appuser/.cache/pip

USER root

# Copy scripts late to avoid rebuilds
COPY watchpuppy watchpuppy.py /app/bin/

# Add watchpuppy to the PATH environment variable
ENV PATH="/app/bin:${PATH}"

WORKDIR /data

# Use non-priviledged user to run app
USER appuser

CMD ["watchpuppy"]