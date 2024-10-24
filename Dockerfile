FROM python:3-alpine

# For logging
ENV LOG_LEVEL=DEBUG

# Install inotify-tools
RUN apk add --no-cache inotify-tools

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
ENV PATH="$(pwd)/venv/bin:$PATH"

# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=bind,source=requirements.txt,target=requirements.txt,readonly \
    python3 -m pip install --upgrade pip \
    && python3 -m pip install -r requirements.txt \
    && rm -rf /tmp/* /home/appuser/.cache/pip

USER root

# Copy scripts late to avoid rebuilds
COPY watchpuppy watchpuppy.py /app/

# Add watchpuppy to the PATH environment variable
ENV PATH="/app/watchpuppy:${PATH}"

WORKDIR /data

# Use non-priviledged user to run app
USER appuser

CMD ["/app/watchpuppy"]