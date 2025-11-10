#!/bin/bash
# Cleanup stopped agent containers and unused volumes
# Usage: cleanup-agents.sh [--all] [--volumes]

set -e

CLEANUP_ALL=false
CLEANUP_VOLUMES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLEANUP_ALL=true
            shift
            ;;
        --volumes)
            CLEANUP_VOLUMES=true
            shift
            ;;
        -h|--help)
            echo "Usage: cleanup-agents.sh [--all] [--volumes]"
            echo ""
            echo "Options:"
            echo "  --all       Remove all containers (including running ones)"
            echo "  --volumes   Also remove unused volumes"
            echo "  -h, --help  Show this help message"
            echo ""
            echo "Examples:"
            echo "  cleanup-agents.sh              # Remove only stopped containers"
            echo "  cleanup-agents.sh --all        # Remove all containers"
            echo "  cleanup-agents.sh --volumes    # Remove stopped containers and unused volumes"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get list of tmux-orchestrator containers
if [ "$CLEANUP_ALL" = true ]; then
    CONTAINERS=$(podman ps -a --filter "ancestor=tmux-orchestrator:latest" --format "{{.Names}}" || echo "")
    echo "Finding all tmux-orchestrator containers..."
else
    CONTAINERS=$(podman ps -a --filter "ancestor=tmux-orchestrator:latest" --filter "status=exited" --format "{{.Names}}" || echo "")
    echo "Finding stopped tmux-orchestrator containers..."
fi

if [ -z "$CONTAINERS" ]; then
    echo "No containers to cleanup"
else
    echo "Containers to remove:"
    echo "$CONTAINERS" | sed 's/^/  - /'
    echo ""

    read -p "Proceed with removal? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$CONTAINERS" | while read -r container; do
            echo "Removing $container..."
            podman rm -f "$container" 2>/dev/null || echo "  Failed to remove $container"
        done
        echo "Container cleanup complete"
    else
        echo "Cleanup cancelled"
        exit 0
    fi
fi

# Cleanup volumes if requested
if [ "$CLEANUP_VOLUMES" = true ]; then
    echo ""
    echo "Cleaning up unused volumes..."
    VOLUMES=$(podman volume ls --filter "dangling=true" --format "{{.Name}}" || echo "")

    if [ -z "$VOLUMES" ]; then
        echo "No unused volumes found"
    else
        echo "Unused volumes:"
        echo "$VOLUMES" | sed 's/^/  - /'
        echo ""

        read -p "Remove these volumes? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman volume prune -f
            echo "Volume cleanup complete"
        else
            echo "Volume cleanup cancelled"
        fi
    fi
fi

echo ""
echo "Cleanup finished!"
