#!/bin/bash
# Send a message to Claude agent in a container
# Usage: send-to-agent.sh <container-name> "<message>"

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: send-to-agent.sh <container-name> \"<message>\""
    echo ""
    echo "Examples:"
    echo "  send-to-agent.sh myagent \"Status update please\""
    echo "  send-to-agent.sh myagent \"Run the tests\""
    exit 1
fi

CONTAINER_NAME="$1"
MESSAGE="$2"

# Check if container exists and is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Send message using tmux (assuming Claude is running in tmux in the container)
# The message is sent to the currently active pane in the container
echo "Sending message to $CONTAINER_NAME..."

# First, try to find tmux session in container
TMUX_SESSION=$(podman exec "$CONTAINER_NAME" tmux ls 2>/dev/null | head -1 | cut -d: -f1 || echo "")

if [ -z "$TMUX_SESSION" ]; then
    echo "Warning: No tmux session found in container"
    echo "The agent might not be running in tmux"
    echo ""
    echo "You can:"
    echo "  1. Connect to container: podman exec -it $CONTAINER_NAME /bin/zsh"
    echo "  2. Start tmux: tmux new -s agent"
    echo "  3. Start Claude: claude"
    exit 1
fi

# Send the message with proper timing (like send-claude-message.sh)
podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_SESSION" "$MESSAGE"
sleep 0.5
podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_SESSION" Enter

echo "Message sent successfully to $CONTAINER_NAME:$TMUX_SESSION"
