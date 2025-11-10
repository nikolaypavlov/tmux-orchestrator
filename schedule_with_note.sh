#!/bin/bash
# Dynamic scheduler with note for next check
# Usage: ./schedule_with_note.sh <minutes> "<note>" [target_window]

MINUTES=${1:-3}
NOTE=${2:-"Standard check-in"}
TARGET=${3:-"tmux-orc:0"}

# Get script directory to make paths dynamic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTE_FILE="$SCRIPT_DIR/next_check_note.txt"

# Create a note file for the next check
echo "=== Next Check Note ($(date)) ===" > "$NOTE_FILE"
echo "Scheduled for: $MINUTES minutes" >> "$NOTE_FILE"
echo "" >> "$NOTE_FILE"
echo "$NOTE" >> "$NOTE_FILE"

echo "Scheduling check in $MINUTES minutes with note: $NOTE"

# Calculate the exact time when the check will run
CURRENT_TIME=$(date +"%H:%M:%S")
RUN_TIME=$(date -v +${MINUTES}M +"%H:%M:%S" 2>/dev/null || date -d "+${MINUTES} minutes" +"%H:%M:%S" 2>/dev/null)

# Detect if target is a container or host tmux session
CONTAINER_NAME=""
TMUX_TARGET=""

# Check if target looks like a container name (no colon means container)
if [[ "$TARGET" != *":"* ]]; then
    # Pure container name
    CONTAINER_NAME="$TARGET"
    TMUX_TARGET="agent:0"  # Default tmux session in container
elif command -v podman &> /dev/null; then
    # Extract potential container name from session:window format
    POTENTIAL_CONTAINER=$(echo "$TARGET" | cut -d: -f1)

    # Check if this session name is actually a container
    if podman ps --format "{{.Names}}" | grep -q "^${POTENTIAL_CONTAINER}$"; then
        CONTAINER_NAME="$POTENTIAL_CONTAINER"
        TMUX_TARGET=$(echo "$TARGET" | cut -d: -f2-)
    else
        # It's a host tmux session
        TMUX_TARGET="$TARGET"
    fi
else
    # No podman, treat as host tmux session
    TMUX_TARGET="$TARGET"
fi

# Use bc for floating point calculation
SECONDS=$(echo "$MINUTES * 60" | bc)

# Build the command based on whether it's a container or host
if [ -n "$CONTAINER_NAME" ]; then
    # Send to containerized agent
    CMD="sleep $SECONDS && podman exec $CONTAINER_NAME tmux send-keys -t '$TMUX_TARGET' 'Time for check! cat $NOTE_FILE' && sleep 0.5 && podman exec $CONTAINER_NAME tmux send-keys -t '$TMUX_TARGET' Enter"
    echo "Scheduling for container: $CONTAINER_NAME (tmux: $TMUX_TARGET)"
else
    # Send to host tmux session
    CMD="sleep $SECONDS && tmux send-keys -t '$TMUX_TARGET' 'Time for orchestrator check! cat $NOTE_FILE' && sleep 0.5 && tmux send-keys -t '$TMUX_TARGET' Enter"
    echo "Scheduling for host tmux session: $TMUX_TARGET"
fi

# Use nohup to completely detach the sleep process
nohup bash -c "$CMD" > /dev/null 2>&1 &

# Get the PID of the background process
SCHEDULE_PID=$!

echo "Scheduled successfully - process detached (PID: $SCHEDULE_PID)"
echo "SCHEDULED TO RUN AT: $RUN_TIME (in $MINUTES minutes from $CURRENT_TIME)"