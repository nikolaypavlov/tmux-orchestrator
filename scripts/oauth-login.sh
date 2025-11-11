#!/bin/bash
# OAuth login helper for containerized Claude agents
# Usage: oauth-login.sh <container-name> [tmux-window]

set -e

CONTAINER_NAME="$1"
TMUX_WINDOW="${2:-1}"  # Default to window 1

if [ -z "$CONTAINER_NAME" ]; then
    echo "Usage: oauth-login.sh <container-name> [tmux-window]"
    exit 1
fi

# Check if container exists
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' not found"
    exit 1
fi

echo "=== OAuth Login Helper ==="
echo "Container: $CONTAINER_NAME"
echo "Tmux window: $TMUX_WINDOW"
echo ""

# Check if credentials already exist
if podman exec "$CONTAINER_NAME" test -f /home/claude/.claude/.credentials.json 2>/dev/null; then
    echo "✓ Credentials already exist in container"
    echo ""
    read -p "Do you want to re-authenticate? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping OAuth login"
        exit 0
    fi
fi

echo "Starting OAuth flow..."
echo ""

# Wait for OAuth prompt to appear
echo "Waiting for Claude to show OAuth prompt..."
sleep 5

# Capture OAuth URL from container
echo "Extracting OAuth URL..."
OAUTH_URL=$(podman exec "$CONTAINER_NAME" tmux capture-pane -t "${CONTAINER_NAME}:${TMUX_WINDOW}" -p -S -100 | grep "https://claude.ai/oauth" -A5 | tr -d '\n' | sed 's/.*\(https:\/\/claude\.ai\/oauth[^ ]*\).*/\1/' | head -1)

if [ -z "$OAUTH_URL" ]; then
    echo "Error: Could not find OAuth URL"
    echo "Make sure Claude is showing the OAuth prompt"
    exit 1
fi

echo "Found OAuth URL:"
echo "$OAUTH_URL"
echo ""

# Open URL in browser
echo "Opening browser for authentication..."
open "$OAUTH_URL" 2>/dev/null || {
    echo "Could not open browser automatically"
    echo "Please open this URL manually:"
    echo "$OAUTH_URL"
}
echo ""

# Wait for user to complete OAuth and get code
echo "After authorizing, you will receive a code."
read -p "Paste the code here: " OAUTH_CODE

if [ -z "$OAUTH_CODE" ]; then
    echo "Error: No code provided"
    exit 1
fi

echo ""
echo "Sending code to container..."

# Send code to container
podman exec "$CONTAINER_NAME" tmux send-keys -t "${CONTAINER_NAME}:${TMUX_WINDOW}" "$OAUTH_CODE" Enter

echo "Waiting for authentication to complete..."
sleep 5

# Check if login succeeded
if podman exec "$CONTAINER_NAME" tmux capture-pane -t "${CONTAINER_NAME}:${TMUX_WINDOW}" -p | grep -q "Logged in as"; then
    # Press Enter to continue
    podman exec "$CONTAINER_NAME" tmux send-keys -t "${CONTAINER_NAME}:${TMUX_WINDOW}" Enter

    sleep 2

    # Check for API key prompt and select "No"
    if podman exec "$CONTAINER_NAME" tmux capture-pane -t "${CONTAINER_NAME}:${TMUX_WINDOW}" -p | grep -q "Do you want to use this API key"; then
        echo "Selecting OAuth authentication (not API key)..."
        podman exec "$CONTAINER_NAME" tmux send-keys -t "${CONTAINER_NAME}:${TMUX_WINDOW}" Enter
        sleep 2
    fi

    echo ""
    echo "✓ OAuth login successful!"
    echo ""

    # Verify credentials were saved
    if podman exec "$CONTAINER_NAME" test -f /home/claude/.claude/.credentials.json 2>/dev/null; then
        EMAIL=$(podman exec "$CONTAINER_NAME" cat /home/claude/.claude.json | jq -r '.oauthAccount.emailAddress' 2>/dev/null || echo "unknown")
        echo "Logged in as: $EMAIL"
        echo "Credentials saved to volume: ${CONTAINER_NAME}-claude-config"
    fi
else
    echo "⚠️  Authentication may have failed"
    echo "Check container output with:"
    echo "  podman exec $CONTAINER_NAME tmux capture-pane -t ${CONTAINER_NAME}:${TMUX_WINDOW} -p | tail -50"
    exit 1
fi
