#!/bin/bash
# Setup orchestrator on host
# Creates tmux session with Claude orchestrator if it doesn't exist
# Usage: setup-orchestrator.sh [template-path]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${1:-$SCRIPT_DIR/../templates/orchestrator-briefing.txt}"

echo "=== Orchestrator Setup ==="

# Check if orchestrator session already exists
if tmux has-session -t orchestrator 2>/dev/null; then
    echo "✓ Orchestrator session already exists"
    echo "  Session: orchestrator"
    echo "  Attach with: tmux attach -t orchestrator"
    exit 0
fi

echo "Creating orchestrator session..."

# Create tmux session named "orchestrator"
tmux new-session -d -s orchestrator

# Get base-index to use correct window number
BASE_INDEX=$(tmux show-options -g base-index | awk '{print $2}')
BASE_INDEX=${BASE_INDEX:-0}

# Rename first window
tmux rename-window -t orchestrator:$BASE_INDEX "Orchestrator"

# Start Claude
echo "Starting Claude as Orchestrator..."
tmux send-keys -t orchestrator:$BASE_INDEX "claude" Enter

# Wait for Claude to start
echo "Waiting for Claude to initialize..."
sleep 5

# Send briefing
if [ -f "$TEMPLATE_PATH" ]; then
    echo "Loading orchestrator briefing from template..."
    BRIEFING=$(cat "$TEMPLATE_PATH")

    # Send briefing
    echo "Briefing Orchestrator..."
    tmux send-keys -t orchestrator:$BASE_INDEX "$BRIEFING"
    sleep 0.5
    tmux send-keys -t orchestrator:$BASE_INDEX Enter

    echo "✓ Orchestrator briefed successfully"
else
    echo "Warning: Template not found at $TEMPLATE_PATH"
    echo "Sending basic briefing..."

    # Fallback basic briefing
    tmux send-keys -t orchestrator:0 "You are the Orchestrator managing containerized AI agent teams. Monitor containers with 'podman ps'. Send messages with './send-claude-message.sh'. Check for running projects and begin oversight."
    sleep 0.5
    tmux send-keys -t orchestrator:0 Enter
fi

echo ""
echo "=== Orchestrator Setup Complete ==="
echo "✓ Session created: orchestrator"
echo "✓ Claude running as Orchestrator"
echo ""
echo "To monitor orchestrator:"
echo "  tmux attach -t orchestrator"
echo ""
echo "To send message to orchestrator:"
echo "  tmux send-keys -t orchestrator:0 'your message' && tmux send-keys -t orchestrator:0 Enter"
echo ""
