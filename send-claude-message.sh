#!/bin/bash

# Send message to Claude agent in tmux window (host or container)
# Usage: send-claude-message.sh <target> <message>
# Target can be:
#   - Host tmux: session:window (e.g., "agentic-seek:3")
#   - Container: container-name (e.g., "myagent")
#   - Container with tmux: container-name:session:window

if [ $# -lt 2 ]; then
    echo "Usage: $0 <target> <message>"
    echo ""
    echo "Examples:"
    echo "  Host tmux:  $0 agentic-seek:3 'Hello Claude!'"
    echo "  Container:  $0 myagent 'Hello Claude!'"
    exit 1
fi

TARGET="$1"
shift  # Remove first argument, rest is the message
MESSAGE="$*"

# Detect if target is a container or host tmux session
CONTAINER_NAME=""
TMUX_TARGET=""

# Check if target looks like a container name (no colon means container)
if [[ "$TARGET" != *":"* ]]; then
    # Pure container name
    CONTAINER_NAME="$TARGET"
    TMUX_TARGET="agent"  # Default tmux session in container
elif command -v podman &> /dev/null; then
    # Extract potential container name from session:window format
    POTENTIAL_CONTAINER=$(echo "$TARGET" | cut -d: -f1)

    # Check if this session name is actually a container
    if podman ps --format "{{.Names}}" | grep -q "^${POTENTIAL_CONTAINER}$"; then
        CONTAINER_NAME="$POTENTIAL_CONTAINER"
        # Rest is tmux target within container
        TMUX_TARGET=$(echo "$TARGET" | cut -d: -f2-)
        # If no tmux target specified, use default
        [ -z "$TMUX_TARGET" ] && TMUX_TARGET="agent"
    else
        # It's a host tmux session
        TMUX_TARGET="$TARGET"
    fi
else
    # No podman, treat as host tmux session
    TMUX_TARGET="$TARGET"
fi

# Send message based on whether it's a container or host
if [ -n "$CONTAINER_NAME" ]; then
    # Send to containerized agent
    if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "Error: Container '$CONTAINER_NAME' is not running"
        exit 1
    fi

    echo "Sending to container: $CONTAINER_NAME (tmux: $TMUX_TARGET)"
    podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_TARGET" "$MESSAGE"
    sleep 0.5
    podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_TARGET" Enter
else
    # Send to host tmux session
    echo "Sending to host tmux: $TMUX_TARGET"
    tmux send-keys -t "$TMUX_TARGET" "$MESSAGE"
    sleep 0.5
    tmux send-keys -t "$TMUX_TARGET" Enter
fi

echo "Message sent: $MESSAGE"