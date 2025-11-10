#!/bin/bash
# Check host setup for tmux-orchestrator
# Verifies tmux-resurrect installation and configuration

set -e

echo "Checking host setup for tmux-orchestrator..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check 1: tmux installed
echo -n "Checking tmux installation... "
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V)
    echo -e "${GREEN}✓${NC} $TMUX_VERSION"
else
    echo -e "${RED}✗${NC} tmux not found"
    echo "  Install with: brew install tmux (macOS) or apt install tmux (Ubuntu)"
    ((ERRORS++))
fi

# Check 2: TPM (Tmux Plugin Manager) installed
echo -n "Checking TPM installation... "
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${GREEN}✓${NC} Found"
else
    echo -e "${YELLOW}⚠${NC} Not found"
    echo "  Install with: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    ((WARNINGS++))
fi

# Check 3: tmux-resurrect plugin installed
echo -n "Checking tmux-resurrect plugin... "
if [ -d "$HOME/.tmux/plugins/tmux-resurrect" ]; then
    echo -e "${GREEN}✓${NC} Found"
else
    echo -e "${RED}✗${NC} Not found"
    echo "  Install with: git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect"
    echo "  Or install via TPM by adding to .tmux.conf:"
    echo "    set -g @plugin 'tmux-plugins/tmux-resurrect'"
    echo "  Then press Ctrl-b + I to install"
    ((ERRORS++))
fi

# Check 4: .tmux.conf exists and has resurrect config
echo -n "Checking .tmux.conf configuration... "
if [ -f "$HOME/.tmux.conf" ]; then
    if grep -q "tmux-resurrect" "$HOME/.tmux.conf"; then
        echo -e "${GREEN}✓${NC} Found resurrect configuration"

        # Check for auto-save interval
        if grep -q "@resurrect-save-interval" "$HOME/.tmux.conf"; then
            INTERVAL=$(grep "@resurrect-save-interval" "$HOME/.tmux.conf" | grep -oE "'[0-9]+'" | tr -d "'")
            echo "  Auto-save interval: ${INTERVAL} minutes"
            if [ "$INTERVAL" != "5" ]; then
                echo -e "  ${YELLOW}⚠${NC} Recommended interval is 5 minutes"
                ((WARNINGS++))
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} Auto-save not configured (recommended: 5 minutes)"
            echo "  Add to .tmux.conf: set -g @resurrect-save-interval '5'"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} resurrect not configured"
        echo "  Add to .tmux.conf:"
        echo "    set -g @plugin 'tmux-plugins/tmux-resurrect'"
        echo "    set -g @resurrect-save-interval '5'"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} .tmux.conf not found"
    echo "  Create one with resurrect configuration"
    ((WARNINGS++))
fi

# Check 5: Podman installed (for containerized agents)
echo -n "Checking Podman installation... "
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version)
    echo -e "${GREEN}✓${NC} $PODMAN_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Podman not found (needed for containerized agents)"
    echo "  Install:"
    echo "    macOS: brew install podman"
    echo "    Ubuntu: apt install podman"
    ((WARNINGS++))
fi

# Check 6: Python3 for tmux_utils.py
echo -n "Checking Python 3... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} $PYTHON_VERSION"
else
    echo -e "${RED}✗${NC} Python 3 not found"
    ((ERRORS++))
fi

echo ""
echo "========================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Host is ready for tmux-orchestrator"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s)${NC}"
    echo "Host is mostly ready, but some optional features are missing"
else
    echo -e "${RED}✗ $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo "Please fix the errors above before running tmux-orchestrator"
fi
echo "========================================"

exit $ERRORS
