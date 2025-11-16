# Registry Directory

This directory stores agent conversation logs and orchestrator notes for host-based agents.

## Structure

```
registry/
├── logs/            # Agent conversation logs
├── notes/           # Orchestrator notes and summaries
└── sessions.json    # Active session tracking (optional)
```

## Usage

### Capturing Agent Logs

When ending an agent, capture the complete conversation:

```bash
tmux capture-pane -t [session]:[window] -S - -E - > \
  registry/logs/[session]_[role]_$(date +%Y%m%d_%H%M%S).log
```

### Log Naming Convention

Format: `{session}_{role}_{timestamp}.log`

Examples:
- `frontend_developer_20241115_143022.log`
- `backend_pm_20241115_143100.log`
- `api_qa_20241115_143200.log`

### Notes Directory

Use for orchestrator planning, decisions, and cross-project notes.

## Container Logs

Note: Containerized agents store logs in Docker/Podman volumes at `/home/claude/logs/`.
This registry/ directory is for host-based agents only.
