# Contributing to Tmux Orchestrator

Thank you for your interest in contributing to the Tmux Orchestrator project! This document provides guidelines and best practices for contributions.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check existing issues to avoid duplicates
2. Create a new issue with a clear title and description
3. Include:
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (OS, tmux version, Podman version)
   - Relevant logs or screenshots

### Submitting Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/tmux-orchestrator.git
   cd tmux-orchestrator
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards below
   - Test your changes thoroughly
   - Update documentation if needed

4. **Commit your changes**
   ```bash
   git add -A
   git commit -m "Add: [clear description of what you added]"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include test results if applicable

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Include `set -e` for error handling
- Add comments for complex logic
- Use meaningful variable names in CAPS for globals
- Quote variables: `"$VARIABLE"` not `$VARIABLE`
- Use bash arithmetic: `$((x * 60))` not `$(echo "$x * 60" | bc)`
- Check command availability: `command -v podman &> /dev/null`

Example:
```bash
#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate input
if [ -z "$1" ]; then
    echo "Error: Missing required argument"
    exit 1
fi
```

### Python Code

- Follow PEP 8 style guide
- Use type hints where appropriate
- Include docstrings for functions and classes
- Use descriptive variable names
- Handle errors gracefully

Example:
```python
def capture_window_content(self, session_name: str, window_index: int, num_lines: int = 50) -> str:
    """
    Safely capture the last N lines from a tmux window

    Args:
        session_name: Name of the tmux session
        window_index: Index of the window to capture
        num_lines: Number of lines to capture (default: 50)

    Returns:
        Captured window content as string
    """
    # Implementation...
```

### Documentation

- Update README.md for user-facing changes
- Update CLAUDE.md for agent behavior changes
- Add examples for new features
- Keep documentation concise and clear

## Project Structure

```
tmux-orchestrator/
├── scripts/          # Automation scripts
├── containers/       # Container configuration
├── templates/        # Agent briefing templates
├── lib/             # Shared library functions
├── registry/        # Agent logs and notes
├── CLAUDE.md        # Agent instructions
├── README.md        # User documentation
└── LEARNINGS.md     # Accumulated knowledge
```

## Testing Guidelines

### Manual Testing

Before submitting a PR, test:

1. **Host Setup**
   ```bash
   ./scripts/check-host-setup.sh
   ```

2. **Container Build**
   ```bash
   podman build -t tmux-orchestrator:latest containers/
   ```

3. **Quick Deploy**
   ```bash
   ./scripts/quick-deploy.sh ~/repos/test-project
   ```

4. **Agent Communication**
   ```bash
   ./send-claude-message.sh test-project "Status check"
   ```

### Test Checklist

- [ ] Scripts run without errors
- [ ] Container builds successfully
- [ ] Agents can communicate
- [ ] OAuth flow works (if changed)
- [ ] Firewall applies correctly (if changed)
- [ ] Documentation is accurate
- [ ] No hardcoded paths or credentials

## Areas for Contribution

### High Priority

- **Agent coordination patterns** - New ways for agents to collaborate
- **Template improvements** - Better briefings for different agent roles
- **Error handling** - More robust error recovery
- **Testing framework** - Automated tests for scripts

### Medium Priority

- **Documentation** - Examples, tutorials, use cases
- **Performance** - Optimizations for large projects
- **Monitoring** - Better visibility into agent status
- **Security** - Additional sandboxing or isolation

### Low Priority

- **UI/UX** - Terminal UI improvements
- **Integrations** - Support for other tools
- **Platform support** - Windows WSL, FreeBSD, etc.

## Code Review Process

1. Maintainers will review your PR within 1-2 weeks
2. Address any requested changes
3. Once approved, a maintainer will merge your PR
4. Your contribution will be included in the next release

## Communication

- Use GitHub issues for bugs and features
- Be respectful and constructive
- Provide context and examples
- Ask questions if unclear

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for helping make Tmux Orchestrator better!
