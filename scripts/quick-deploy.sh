#!/bin/bash
# Quick deploy - One command to deploy complete agent team
# Usage: quick-deploy.sh <project-path> [--firewall]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
PROJECT_PATH=""
ENABLE_FIREWALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --firewall)
            ENABLE_FIREWALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: quick-deploy.sh <project-path> [--firewall]"
            echo ""
            echo "Deploy a complete AI agent team for a project in one command."
            echo ""
            echo "Arguments:"
            echo "  <project-path>    Path to your project directory"
            echo ""
            echo "Options:"
            echo "  --firewall        Enable network firewall in container"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Example:"
            echo "  ./scripts/quick-deploy.sh ~/repos/my-project --firewall"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
            else
                echo "Error: Multiple project paths specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate project path
if [ -z "$PROJECT_PATH" ]; then
    echo "Error: Project path is required"
    echo "Usage: quick-deploy.sh <project-path> [--firewall]"
    exit 1
fi

# Resolve absolute path
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project directory does not exist: $PROJECT_PATH"
    exit 1
fi

# Extract project name from path
PROJECT_NAME=$(basename "$PROJECT_PATH")
# Clean project name for container (replace spaces with hyphens, lowercase)
CONTAINER_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

echo "========================================="
echo "Quick Deploy: $PROJECT_NAME"
echo "========================================="
echo ""

# Step 1: Setup orchestrator
echo "Step 1/3: Checking orchestrator..."
"$SCRIPT_DIR/setup-orchestrator.sh"
echo ""

# Step 2: Spawn container with auto-init
echo "Step 2/3: Spawning agent container..."
SPAWN_ARGS=(
    "$SCRIPT_DIR/spawn-agent.sh"
    "--role" "pm"
    "--project" "$PROJECT_PATH"
    "--name" "$CONTAINER_NAME"
    "--auto-init"
)

if [ "$ENABLE_FIREWALL" = true ]; then
    SPAWN_ARGS+=("--firewall")
fi

"${SPAWN_ARGS[@]}"
echo ""

# Step 3: Notify orchestrator about new project
echo "Step 3/3: Notifying orchestrator..."
sleep 2  # Give PM a moment to initialize

# Send notification to orchestrator
NOTIFICATION="NEW PROJECT DEPLOYED:
Project: $PROJECT_NAME
Container: $CONTAINER_NAME
Location: $PROJECT_PATH
PM Status: Initializing team...

Use these commands to monitor:
- View PM: podman exec $CONTAINER_NAME tmux capture-pane -t $PROJECT_NAME:0 -p | tail -50
- Send message: ./send-claude-message.sh $CONTAINER_NAME \"your message\"
- Attach to PM: podman exec -it $CONTAINER_NAME tmux attach -t $PROJECT_NAME"

tmux send-keys -t orchestrator:0 "$NOTIFICATION"
sleep 0.5
tmux send-keys -t orchestrator:0 Enter

echo -e "${GREEN}✓ Orchestrator notified${NC}"
echo ""

# Success summary
echo "========================================="
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "========================================="
echo ""
echo "Project: $PROJECT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Status: PM is initializing team autonomously"
echo ""
echo "Monitor orchestrator:"
echo -e "  ${YELLOW}tmux attach -t orchestrator${NC}"
echo ""
echo "View PM activity:"
echo "  podman exec $CONTAINER_NAME tmux capture-pane -t $PROJECT_NAME:0 -p | tail -50"
echo ""
echo "Attach to PM session:"
echo "  podman exec -it $CONTAINER_NAME tmux attach -t $PROJECT_NAME"
echo ""
echo "Send message to PM:"
echo "  ./send-claude-message.sh $CONTAINER_NAME \"Status update please\""
echo ""
echo "Check all containers:"
echo "  podman ps"
echo ""
