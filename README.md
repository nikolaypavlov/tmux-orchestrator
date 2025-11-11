![Orchestrator Hero](/Orchestrator.png)

**Run AI agents 24/7 while you sleep** - The Tmux Orchestrator enables Claude agents to work autonomously, schedule their own check-ins, and coordinate across multiple projects without human intervention.

## 🤖 Key Capabilities & Autonomous Features

- **Self-trigger** - Agents schedule their own check-ins and continue work autonomously
- **Coordinate** - Project managers assign tasks to engineers across multiple codebases  
- **Persist** - Work continues even when you close your laptop
- **Scale** - Run multiple teams working on different projects simultaneously

## 🏗️ Architecture

The Tmux Orchestrator uses a three-tier hierarchy to overcome context window limitations:

```
┌─────────────┐
│ Orchestrator│ ← You interact here
└──────┬──────┘
       │ Monitors & coordinates
       ▼
┌─────────────┐     ┌─────────────┐
│  Project    │     │  Project    │
│  Manager 1  │     │  Manager 2  │ ← Assign tasks, enforce specs
└──────┬──────┘     └──────┬──────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│ Engineer 1  │     │ Engineer 2  │ ← Write code, fix bugs
└─────────────┘     └─────────────┘
```

### Why Separate Agents?
- **Limited context windows** - Each agent stays focused on its role
- **Specialized expertise** - PMs manage, engineers code
- **Parallel work** - Multiple engineers can work simultaneously
- **Better memory** - Smaller contexts mean better recall

## 📸 Examples in Action

### Project Manager Coordination
![Initiate Project Manager](Examples/Initiate%20Project%20Manager.png)
*The orchestrator creating and briefing a new project manager agent*

### Status Reports & Monitoring
![Status Reports](Examples/Status%20reports.png)
*Real-time status updates from multiple agents working in parallel*

### Tmux Communication
![Reading TMUX Windows and Sending Messages](Examples/Reading%20TMUX%20Windows%20and%20Sending%20Messages.png)
*How agents communicate across tmux windows and sessions*

### Project Completion
![Project Completed](Examples/Project%20Completed.png)
*Successful project completion with all tasks verified and committed*

## 🎯 Quick Start

### One-Command Deployment (Recommended)

Deploy a complete AI agent team for any project in one command:

```bash
# 1. Build the container image (first time only)
podman build -t tmux-orchestrator:latest containers/

# 2. Deploy agent team for your project
./scripts/quick-deploy.sh ~/repos/my-project

# Optional: Enable network firewall
./scripts/quick-deploy.sh ~/repos/my-project --firewall
```

That's it! This single command will:
1. ✅ Create orchestrator on host (if not exists)
2. ✅ Spawn containerized PM with auto-initialized team
3. ✅ Notify orchestrator about the new project
4. ✅ Start autonomous work on the codebase

### Monitor Your Agents

```bash
# View orchestrator
tmux attach -t orchestrator

# Check PM status
podman exec my-project tmux capture-pane -t my-project:0 -p | tail -50

# Send message to PM
./send-claude-message.sh my-project "Status update please"

# Attach to PM session (full interactivity)
podman exec -it my-project tmux attach -t my-project

# List all running containers
podman ps
```

### What Happens Behind the Scenes

1. **Orchestrator Setup**: Creates tmux session on host, starts Claude with orchestrator briefing
2. **Container Spawn**: Creates Podman container with project mounted at `/workspace`
3. **PM Initialization**: Inside container, creates tmux session, starts Claude as PM, loads briefing template
4. **Autonomous Operation**: PM analyzes project, creates Developer team, starts work
5. **Notification**: Orchestrator receives project status and monitoring commands

### Manual Setup (Advanced)

For more control over the setup process, you can use individual scripts:

```bash
# 1. Setup orchestrator manually
./scripts/setup-orchestrator.sh

# 2. Spawn agent with custom options
./scripts/spawn-agent.sh \
  --role pm \
  --project ~/repos/my-project \
  --name my-project \
  --auto-init \
  --firewall
```

## 🖥️ Host Setup

### Prerequisites

Before running the orchestrator, ensure your host machine is properly configured:

#### 1. Install tmux-resurrect (Required for Session Persistence)

**macOS:**
```bash
# Install TPM (Tmux Plugin Manager)
# Standard location:
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Or XDG location:
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

**Ubuntu/Linux:**
```bash
# Same as macOS - choose standard or XDG location
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Or:
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Add to `~/.tmux.conf` or `~/.config/tmux/tmux.conf`:
```bash
# Enable TPM
set -g @plugin 'tmux-plugins/tpm'

# Enable tmux-resurrect for session persistence
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Auto-save every 5 minutes (highly recommended!)
set -g @resurrect-save-interval '5'

# Initialize TPM (keep this at bottom of config)
# Adjust path based on your installation location:
run '~/.tmux/plugins/tpm/tpm'
# Or for XDG:
# run '~/.config/tmux/plugins/tpm/tpm'
```

Then install plugins:
```bash
# Inside tmux, press: Ctrl-b + I (capital i)
# Or run: ~/.tmux/plugins/tpm/bin/install_plugins
# (or ~/.config/tmux/plugins/tpm/bin/install_plugins for XDG)
```

**Using tmux-resurrect:**
- `Ctrl-b Ctrl-s` - Manually save session
- `Ctrl-b Ctrl-r` - Restore last saved session
- Auto-saves every 5 minutes (configured above)

#### 2. Install Podman (Optional, for Containerized Agents)

**macOS:**
```bash
brew install podman

# Initialize Podman machine
podman machine init
podman machine start
```

**Ubuntu/Linux:**
```bash
sudo apt update
sudo apt install podman
```

#### 3. Verify Setup

Run the setup checker:
```bash
./scripts/check-host-setup.sh
```

This will verify:
- ✓ tmux installation
- ✓ tmux-resurrect plugin
- ✓ Auto-save configuration
- ✓ Podman availability
- ✓ Python 3 for utilities

## 🐳 Containerized Agents (Optional)

For improved security and isolation, agents can run in Podman containers.

### Build Container Image

```bash
# Build the agent container image
podman build -t tmux-orchestrator:latest containers/
```

### Spawn Containerized Agent

```bash
# Create a containerized developer agent
./scripts/spawn-agent.sh \
  --role developer \
  --project ~/my-project \
  --name myproject-dev \
  --firewall

# Connect to the agent
podman exec -it myproject-dev /bin/zsh

# Inside container, start Claude
claude
```

### Send Messages to Containerized Agents

The existing scripts automatically detect containers:

```bash
# Send to containerized agent (automatically detected)
./send-claude-message.sh myproject-dev "Status update please"

# Send to host tmux session
./send-claude-message.sh frontend:0 "Your message"
```

### Container Management

```bash
# List running agent containers
podman ps

# Stop an agent
podman stop myproject-dev

# Cleanup stopped containers
./scripts/cleanup-agents.sh

# Cleanup with volumes
./scripts/cleanup-agents.sh --volumes
```

## ✨ Key Features

### 🔄 Self-Scheduling Agents
Agents can schedule their own check-ins using:
```bash
./schedule_with_note.sh 30 "Continue dashboard implementation"
```

### 👥 Multi-Agent Coordination
- Project managers communicate with engineers
- Orchestrator monitors all project managers
- Cross-project knowledge sharing

### 💾 Automatic Git Backups
- Commits every 30 minutes of work
- Tags stable versions
- Creates feature branches for experiments

### 📊 Real-Time Monitoring
- See what every agent is doing
- Intervene when needed
- Review progress across all projects

## 📋 Best Practices

### Writing Effective Specifications

```markdown
PROJECT: E-commerce Checkout
GOAL: Implement multi-step checkout process

CONSTRAINTS:
- Use existing cart state management
- Follow current design system
- Maximum 3 API endpoints
- Commit after each step completion

DELIVERABLES:
1. Shipping address form with validation
2. Payment method selection (Stripe integration)
3. Order review and confirmation page
4. Success/failure handling

SUCCESS CRITERIA:
- All forms validate properly
- Payment processes without errors  
- Order data persists to database
- Emails send on completion
```

### Git Safety Rules

1. **Before Starting Any Task**
   ```bash
   git checkout -b feature/[task-name]
   git status  # Ensure clean state
   ```

2. **Every 30 Minutes**
   ```bash
   git add -A
   git commit -m "Progress: [what was accomplished]"
   ```

3. **When Task Completes**
   ```bash
   git tag stable-[feature]-[date]
   git checkout main
   git merge feature/[task-name]
   ```

## 🚨 Common Pitfalls & Solutions

| Pitfall | Consequence | Solution |
|---------|-------------|----------|
| Vague instructions | Agent drift, wasted compute | Write clear, specific specs |
| No git commits | Lost work, frustrated devs | Enforce 30-minute commit rule |
| Too many tasks | Context overload, confusion | One task per agent at a time |
| No specifications | Unpredictable results | Always start with written spec |
| Missing checkpoints | Agents stop working | Schedule regular check-ins |

## 🛠️ How It Works

### The Magic of Tmux
Tmux (terminal multiplexer) is the key enabler because:
- It persists terminal sessions even when disconnected
- Allows multiple windows/panes in one session
- Claude runs in the terminal, so it can control other Claude instances
- Commands can be sent programmatically to any window

### 💬 Simplified Agent Communication

We now use the `send-claude-message.sh` script for all agent communication:

```bash
# Send message to any Claude agent
./send-claude-message.sh session:window "Your message here"

# Examples:
./send-claude-message.sh frontend:0 "What's your progress on the login form?"
./send-claude-message.sh backend:1 "The API endpoint /api/users is returning 404"
./send-claude-message.sh project-manager:0 "Please coordinate with the QA team"
```

The script handles all timing complexities automatically, making agent communication reliable and consistent.

### Scheduling Check-ins
```bash
# Schedule with specific, actionable notes
./schedule_with_note.sh 30 "Review auth implementation, assign next task"
./schedule_with_note.sh 60 "Check test coverage, merge if passing"
./schedule_with_note.sh 120 "Full system check, rotate tasks if needed"
```

**Important**: The orchestrator needs to know which tmux window it's running in to schedule its own check-ins correctly. If scheduling isn't working, verify the orchestrator knows its current window with:
```bash
echo "Current window: $(tmux display-message -p "#{session_name}:#{window_index}")"
```

## 🎓 Advanced Usage

### Multi-Project Orchestration
```bash
# Start orchestrator
tmux new-session -s orchestrator

# Create project managers for each project
tmux new-window -n frontend-pm
tmux new-window -n backend-pm  
tmux new-window -n mobile-pm

# Each PM manages their own engineers
# Orchestrator coordinates between PMs
```

### Cross-Project Intelligence
The orchestrator can share insights between projects:
- "Frontend is using /api/v2/users, update backend accordingly"
- "Authentication is working in Project A, use same pattern in Project B"
- "Performance issue found in shared library, fix across all projects"

## 📚 Core Files

- `send-claude-message.sh` - Simplified agent communication script
- `schedule_with_note.sh` - Self-scheduling functionality
- `tmux_utils.py` - Tmux interaction utilities
- `CLAUDE.md` - Agent behavior instructions
- `LEARNINGS.md` - Accumulated knowledge base

## 🤝 Contributing & Optimization

The orchestrator evolves through community discoveries and optimizations. When contributing:

1. Document new tmux commands and patterns in CLAUDE.md
2. Share novel use cases and agent coordination strategies
3. Submit optimizations for claudes synchronization
4. Keep command reference up-to-date with latest findings
5. Test improvements across multiple sessions and scenarios

Key areas for enhancement:
- Agent communication patterns
- Cross-project coordination
- Novel automation workflows

## 📄 License

MIT License - Use freely but wisely. Remember: with great automation comes great responsibility.

---

*"The tools we build today will program themselves tomorrow"* - Alan Kay, 1971