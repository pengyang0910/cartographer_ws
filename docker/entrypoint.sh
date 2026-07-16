#!/bin/bash
set -e

# ------------------------------------------------------------
# Entrypoint for Cartographer ROS 2 Docker environment
# ------------------------------------------------------------

WS_DIR="${WS_DIR:-/workspace}"
HOST_USER="${HOST_USER:-parry}"
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

# Create user if it doesn't exist
if ! id -u "$HOST_USER" >/dev/null 2>&1; then
    groupadd --gid "$HOST_GID" "$HOST_USER"
    useradd --uid "$HOST_UID" --gid "$HOST_GID" -m -s /bin/bash "$HOST_USER"
    echo "$HOST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$HOST_USER
fi

# If HOST_UID differs from existing user, update it
CURRENT_UID=$(id -u "$HOST_USER")
if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    usermod -u "$HOST_UID" "$HOST_USER"
    groupmod -g "$HOST_GID" "$HOST_USER"
    chown -R "$HOST_USER:$HOST_USER" "/home/$HOST_USER"
fi

# Ensure the workspace is owned by the target user
if [ -d "$WS_DIR" ]; then
    chown -R "$HOST_USER:$HOST_USER" "$WS_DIR" 2>/dev/null || true
fi

# Drop into the target user and run the requested command
if [ $# -eq 0 ]; then
    exec gosu "$HOST_USER" /bin/bash
else
    exec gosu "$HOST_USER" "$@"
fi
