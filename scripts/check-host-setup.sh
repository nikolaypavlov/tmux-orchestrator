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
TPM_FOUND=false
TPM_LOCATION=""
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    TPM_FOUND=true
    TPM_LOCATION="$HOME/.tmux/plugins/tpm"
elif [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
    TPM_FOUND=true
    TPM_LOCATION="$HOME/.config/tmux/plugins/tpm"
fi

if [ "$TPM_FOUND" = true ]; then
    echo -e "${GREEN}✓${NC} Found at $TPM_LOCATION"
else
    echo -e "${YELLOW}⚠${NC} Not found"
    echo "  Install with:"
    echo "    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    echo "    or: git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm"
    ((WARNINGS++))
fi

# Check 3: tmux-resurrect plugin installed
echo -n "Checking tmux-resurrect plugin... "
RESURRECT_FOUND=false
RESURRECT_LOCATION=""
if [ -d "$HOME/.tmux/plugins/tmux-resurrect" ]; then
    RESURRECT_FOUND=true
    RESURRECT_LOCATION="$HOME/.tmux/plugins/tmux-resurrect"
elif [ -d "$HOME/.config/tmux/plugins/tmux-resurrect" ]; then
    RESURRECT_FOUND=true
    RESURRECT_LOCATION="$HOME/.config/tmux/plugins/tmux-resurrect"
fi

if [ "$RESURRECT_FOUND" = true ]; then
    echo -e "${GREEN}✓${NC} Found at $RESURRECT_LOCATION"
else
    echo -e "${RED}✗${NC} Not found"
    echo "  Install with:"
    echo "    git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect"
    echo "    or: git clone https://github.com/tmux-plugins/tmux-resurrect ~/.config/tmux/plugins/tmux-resurrect"
    echo "  Or install via TPM by adding to tmux config:"
    echo "    set -g @plugin 'tmux-plugins/tmux-resurrect'"
    echo "  Then press Ctrl-b + I to install"
    ((ERRORS++))
fi

# Check 4: tmux.conf exists and has resurrect config
echo -n "Checking tmux configuration... "
TMUX_CONF=""
if [ -f "$HOME/.tmux.conf" ]; then
    TMUX_CONF="$HOME/.tmux.conf"
elif [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    TMUX_CONF="$HOME/.config/tmux/tmux.conf"
fi

if [ -n "$TMUX_CONF" ]; then
    if grep -q "tmux-resurrect" "$TMUX_CONF"; then
        echo -e "${GREEN}✓${NC} Found resurrect configuration in $TMUX_CONF"

        # Check for auto-save interval
        if grep -q "@resurrect-save-interval" "$TMUX_CONF"; then
            INTERVAL=$(grep "@resurrect-save-interval" "$TMUX_CONF" | grep -oE "'[0-9]+'" | tr -d "'")
            echo "  Auto-save interval: ${INTERVAL} minutes"
            if [ "$INTERVAL" != "5" ]; then
                echo -e "  ${YELLOW}⚠${NC} Recommended interval is 5 minutes"
                ((WARNINGS++))
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} Auto-save not configured (recommended: 5 minutes)"
            echo "  Add to config: set -g @resurrect-save-interval '5'"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} resurrect not configured in $TMUX_CONF"
        echo "  Add to config:"
        echo "    set -g @plugin 'tmux-plugins/tmux-resurrect'"
        echo "    set -g @resurrect-save-interval '5'"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} tmux.conf not found"
    echo "  Create one at ~/.tmux.conf or ~/.config/tmux/tmux.conf"
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
