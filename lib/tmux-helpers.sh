#!/bin/bash
# Shared helper functions for tmux orchestration
# Source this file in your scripts: source "$(dirname "$0")/lib/tmux-helpers.sh"

# Detect if target is a container or host tmux session
# Usage: detect_target_type "target"
# Sets: CONTAINER_NAME and TMUX_TARGET global variables
detect_target_type() {
    local TARGET="$1"

    CONTAINER_NAME=""
    TMUX_TARGET=""

    # Check if target looks like a container name (no colon means container)
    if [[ "$TARGET" != *":"* ]]; then
        # Pure container name
        CONTAINER_NAME="$TARGET"
        TMUX_TARGET="agent:0"  # Default tmux session in container
    elif command -v podman &> /dev/null; then
        # Extract potential container name from session:window format
        local POTENTIAL_CONTAINER=$(echo "$TARGET" | cut -d: -f1)

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

    # Export for use in calling script
    export CONTAINER_NAME
    export TMUX_TARGET
}

# Substitute template placeholders
# Usage: substitute_template "template_content" "project_name" "container_name" "project_type"
# Returns: Template with substituted values
substitute_template() {
    local TEMPLATE="$1"
    local PROJECT_NAME="$2"
    local CONTAINER_NAME="$3"
    local PROJECT_TYPE="$4"

    # Perform substitutions
    TEMPLATE="${TEMPLATE//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    TEMPLATE="${TEMPLATE//\{\{CONTAINER_NAME\}\}/$CONTAINER_NAME}"
    TEMPLATE="${TEMPLATE//\{\{PROJECT_TYPE\}\}/$PROJECT_TYPE}"

    echo "$TEMPLATE"
}

# Load and substitute template from file
# Usage: load_template "template_path" "project_name" "container_name" "project_type"
# Returns: Substituted template content
load_template() {
    local TEMPLATE_PATH="$1"
    local PROJECT_NAME="$2"
    local CONTAINER_NAME="$3"
    local PROJECT_TYPE="$4"

    if [ ! -f "$TEMPLATE_PATH" ]; then
        echo "Error: Template file not found: $TEMPLATE_PATH" >&2
        return 1
    fi

    local TEMPLATE=$(cat "$TEMPLATE_PATH")
    substitute_template "$TEMPLATE" "$PROJECT_NAME" "$CONTAINER_NAME" "$PROJECT_TYPE"
}

# Send message to tmux target (container or host)
# Usage: send_to_target "target" "message"
send_to_target() {
    local TARGET="$1"
    local MESSAGE="$2"

    detect_target_type "$TARGET"

    if [ -n "$CONTAINER_NAME" ]; then
        # Send to container
        podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_TARGET" "$MESSAGE"
        sleep 0.5
        podman exec "$CONTAINER_NAME" tmux send-keys -t "$TMUX_TARGET" Enter
    else
        # Send to host tmux session
        tmux send-keys -t "$TMUX_TARGET" "$MESSAGE"
        sleep 0.5
        tmux send-keys -t "$TMUX_TARGET" Enter
    fi
}

# Capture pane content from container or host
# Usage: capture_pane "target" [lines]
capture_pane() {
    local TARGET="$1"
    local LINES="${2:-50}"

    detect_target_type "$TARGET"

    if [ -n "$CONTAINER_NAME" ]; then
        # Capture from container
        podman exec "$CONTAINER_NAME" tmux capture-pane -t "$TMUX_TARGET" -p | tail -n "$LINES"
    else
        # Capture from host
        tmux capture-pane -t "$TMUX_TARGET" -p | tail -n "$LINES"
    fi
}

# Check if tmux session exists
# Usage: tmux_session_exists "session_name"
# Returns: 0 if exists, 1 if not
tmux_session_exists() {
    local SESSION_NAME="$1"
    tmux has-session -t "$SESSION_NAME" 2>/dev/null
}

# Check if container is running
# Usage: container_running "container_name"
# Returns: 0 if running, 1 if not
container_running() {
    local CONTAINER_NAME="$1"

    if ! command -v podman &> /dev/null; then
        return 1
    fi

    podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}
