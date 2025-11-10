#!/bin/bash
# Execute commands in a Claude agent container
# Usage: agent-exec.sh <container-name> <command>

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: agent-exec.sh <container-name> <command>"
    echo ""
    echo "Examples:"
    echo "  agent-exec.sh myagent 'ls -la /workspace'"
    echo "  agent-exec.sh myagent 'git status'"
    echo "  agent-exec.sh myagent 'tmux ls'"
    exit 1
fi

CONTAINER_NAME="$1"
shift
COMMAND="$*"

# Check if container exists
if ! podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' does not exist"
    exit 1
fi

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    echo "Start it with: podman start $CONTAINER_NAME"
    exit 1
fi

# Execute command
podman exec -it "$CONTAINER_NAME" /bin/zsh -c "$COMMAND"
