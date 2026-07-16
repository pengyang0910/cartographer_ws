#!/bin/bash
set -e

# ------------------------------------------------------------
# Run Cartographer ROS 2 Docker container
#
# The image is fully self-contained (ROS 2, cartographer,
# cartographer_ros source are all inside). The host workspace
# is mounted at /workspace for development convenience.
# ------------------------------------------------------------

IMAGE_NAME="${IMAGE_NAME:-cartographer-ubuntu2204-humble:v1.0}"
CONTAINER_NAME="${CONTAINER_NAME:-cartographer-dev}"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Check if image exists; offer to build if not
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Image '$IMAGE_NAME' not found."
    echo ""
    read -r -p "Build it now? [Y/n] " answer
    if [ "$answer" != "n" ] && [ "$answer" != "N" ]; then
        echo "Building $IMAGE_NAME ..."
        docker build -t "$IMAGE_NAME" -f "$(dirname "$0")/Dockerfile" "$WORKSPACE_DIR"
    else
        echo "Aborted."
        exit 1
    fi
fi

# Allow overriding display for GUI tools (rviz2, etc.)
if [ -n "$DISPLAY" ]; then
    XSOCK=/tmp/.X11-unix
    XAUTH=/tmp/.docker.xauth
    touch "$XAUTH"
    xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge -
    X11_ARGS=(-e DISPLAY="$DISPLAY" -e XAUTHORITY="$XAUTH" -v "$XSOCK:$XSOCK:rw" -v "$XAUTH:$XAUTH:rw")
else
    echo "  (no DISPLAY set — skipping X11 forwarding)"
    X11_ARGS=()
fi

# Allow overriding network mode
NETWORK_MODE="${NETWORK_MODE:-host}"

echo "Starting container '$CONTAINER_NAME' ..."
echo "  Workspace:  $WORKSPACE_DIR -> /workspace"
echo "  User:       $USER (uid=$(id -u), gid=$(id -g))"
echo ""

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK_MODE" \
    "${X11_ARGS[@]}" \
    -e HOST_USER="$USER" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e WS_DIR=/workspace \
    -v "$WORKSPACE_DIR:/workspace" \
    -v /dev:/dev:ro \
    --privileged \
    "$IMAGE_NAME" \
    "$@"
