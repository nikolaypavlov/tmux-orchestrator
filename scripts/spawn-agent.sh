#!/bin/bash
# Spawn a new Claude agent in a Podman container
# Usage: spawn-agent.sh --role <role> --project <path> --name <container-name> [--firewall]

set -e

# Default values
ROLE="developer"
PROJECT_PATH=""
CONTAINER_NAME=""
ENABLE_FIREWALL=false
IMAGE_NAME="tmux-orchestrator:latest"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --role)
            ROLE="$2"
            shift 2
            ;;
        --project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --firewall)
            ENABLE_FIREWALL=true
            shift
            ;;
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: spawn-agent.sh --role <role> --project <path> --name <container-name> [--firewall]"
            echo ""
            echo "Options:"
            echo "  --role <role>        Agent role (developer, qa, devops, pm, etc.)"
            echo "  --project <path>     Path to project directory (will be mounted at /workspace)"
            echo "  --name <name>        Container name (required)"
            echo "  --firewall           Enable firewall restrictions (requires CAP_NET_ADMIN)"
            echo "  --image <image>      Docker image name (default: tmux-orchestrator:latest)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Container name is required (--name)"
    exit 1
fi

if [ -z "$PROJECT_PATH" ]; then
    echo "Error: Project path is required (--project)"
    exit 1
fi

# Resolve absolute project path
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

# Check if project path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

# Check if container already exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container with name '$CONTAINER_NAME' already exists"
    echo "Use 'podman rm $CONTAINER_NAME' to remove it first"
    exit 1
fi

# Check if image exists
if ! podman image exists "$IMAGE_NAME"; then
    echo "Error: Image '$IMAGE_NAME' not found"
    echo "Build it first with: podman build -t $IMAGE_NAME containers/"
    exit 1
fi

# Prepare Podman run command
PODMAN_ARGS=(
    "run"
    "-d"
    "--name" "$CONTAINER_NAME"
    "-v" "${PROJECT_PATH}:/workspace:Z"
    "-v" "${CONTAINER_NAME}-logs:/home/claude/logs:Z"
    "-e" "AGENT_ROLE=$ROLE"
    "-e" "CONTAINER_NAME=$CONTAINER_NAME"
)

# Add firewall capabilities if enabled
if [ "$ENABLE_FIREWALL" = true ]; then
    PODMAN_ARGS+=(
        "--cap-add" "CAP_NET_ADMIN"
        "--cap-add" "CAP_NET_RAW"
    )
    echo "Firewall enabled: container will have restricted network access"
fi

# Add Anthropic credentials if they exist
if [ -d "$HOME/.anthropic" ]; then
    PODMAN_ARGS+=("-v" "$HOME/.anthropic:/home/claude/.anthropic:ro,Z")
fi

# Run the container
echo "Spawning agent container..."
echo "  Role: $ROLE"
echo "  Project: $PROJECT_PATH"
echo "  Container: $CONTAINER_NAME"

podman "${PODMAN_ARGS[@]}" "$IMAGE_NAME" tail -f /dev/null

# Initialize firewall if enabled
if [ "$ENABLE_FIREWALL" = true ]; then
    echo "Initializing firewall..."
    podman exec "$CONTAINER_NAME" bash /usr/local/bin/init-firewall.sh || {
        echo "Warning: Firewall initialization failed"
    }
fi

echo ""
echo "Agent container spawned successfully!"
echo ""
echo "Next steps:"
echo "  1. Connect to container: podman exec -it $CONTAINER_NAME /bin/zsh"
echo "  2. Start Claude: claude"
echo "  3. Or send message: ./scripts/send-to-agent.sh $CONTAINER_NAME \"Your message\""
echo ""
echo "Container info:"
echo "  Name: $CONTAINER_NAME"
echo "  Role: $ROLE"
echo "  Workspace: /workspace (mounted from $PROJECT_PATH)"
echo "  Logs: ${CONTAINER_NAME}-logs volume"
