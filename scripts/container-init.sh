#!/bin/bash
# Container initialization script
# Runs inside container to set up PM and team structure
# Usage: container-init.sh <project-name> <container-name> [template-path]

set -e

PROJECT_NAME="${1:-project}"
CONTAINER_NAME="${2:-$PROJECT_NAME}"
TEMPLATE_PATH="${3:-/home/claude/.tmux-orchestrator/templates/pm-briefing.txt}"

echo "=== Container Init for $PROJECT_NAME ==="

# Detect project type
PROJECT_TYPE="unknown"
if [ -f "/workspace/package.json" ]; then
    PROJECT_TYPE="nodejs"
elif [ -f "/workspace/requirements.txt" ] || [ -f "/workspace/pyproject.toml" ]; then
    PROJECT_TYPE="python"
elif [ -f "/workspace/go.mod" ]; then
    PROJECT_TYPE="go"
elif [ -f "/workspace/Cargo.toml" ]; then
    PROJECT_TYPE="rust"
fi

echo "Detected project type: $PROJECT_TYPE"

# Create tmux session
echo "Creating tmux session: $PROJECT_NAME"
tmux new-session -d -s "$PROJECT_NAME" -c "/workspace"

# Get base-index to use correct window number
BASE_INDEX=$(tmux show-options -g base-index 2>/dev/null | awk '{print $2}')
BASE_INDEX=${BASE_INDEX:-0}

# Rename first window to Project-Manager
tmux rename-window -t "$PROJECT_NAME:$BASE_INDEX" "Project-Manager"

# Start Claude in first window with skip permissions for autonomous operation
# Safe in containers due to isolation (firewall + bind mount)
echo "Starting Claude as PM in window $BASE_INDEX..."
tmux send-keys -t "$PROJECT_NAME:$BASE_INDEX" "claude --dangerously-skip-permissions" Enter

# Wait for Claude to start
echo "Waiting for Claude to initialize..."
sleep 5

# Prepare PM briefing with substitutions
if [ -f "$TEMPLATE_PATH" ]; then
    echo "Loading PM briefing from template..."
    BRIEFING=$(cat "$TEMPLATE_PATH")

    # Replace placeholders
    BRIEFING="${BRIEFING//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    BRIEFING="${BRIEFING//\{\{CONTAINER_NAME\}\}/$CONTAINER_NAME}"
    BRIEFING="${BRIEFING//\{\{PROJECT_TYPE\}\}/$PROJECT_TYPE}"

    # Send briefing to PM
    echo "Briefing PM..."
    tmux send-keys -t "$PROJECT_NAME:$BASE_INDEX" "$BRIEFING"
    sleep 0.5
    tmux send-keys -t "$PROJECT_NAME:$BASE_INDEX" Enter

    echo "PM briefed successfully"
else
    echo "Warning: Template not found at $TEMPLATE_PATH"
    echo "Sending basic briefing..."

    # Fallback basic briefing
    tmux send-keys -t "$PROJECT_NAME:$BASE_INDEX" "You are the Project Manager for $PROJECT_NAME. Analyze the project in /workspace, create a Developer in window 1, and coordinate the team."
    sleep 0.5
    tmux send-keys -t "$PROJECT_NAME:$BASE_INDEX" Enter
fi

echo ""
echo "=== Container Init Complete ==="
echo "PM is running in: $PROJECT_NAME:$BASE_INDEX"
echo ""
echo "To monitor PM:"
echo "  podman exec $CONTAINER_NAME tmux attach -t $PROJECT_NAME"
echo ""
echo "To send message to PM:"
echo "  ./send-claude-message.sh $CONTAINER_NAME \"your message\""
echo ""
