# Tmux Orchestrator Agent Container
# Ubuntu 24.04 with modern CLI tools and Claude Code

FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install system dependencies and modern CLI tools
RUN apt-get update && apt-get install -y \
    # Core development tools
    tmux \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    # Modern CLI tools
    fzf \
    fd-find \
    bat \
    ipcalc \
    jq \
    entr \
    ripgrep \
    tree \
    # Network and firewall tools
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    netcat-openbsd \
    # Shell and editors
    zsh \
    vim \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Build essentials for compiling packages
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (LTS) for Claude CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user 'claude'
RUN useradd -m -s /bin/zsh claude \
    && mkdir -p /workspace /home/claude/logs /home/claude/.config \
    && chown -R claude:claude /workspace /home/claude

# Create symlinks for modern CLI tools (Ubuntu-specific naming)
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat

# Switch to claude user
USER claude
WORKDIR /home/claude

# Copy tmux configuration
COPY --chown=claude:claude agent-tmux.conf /home/claude/.tmux.conf

# Copy firewall initialization script
COPY --chown=claude:claude init-firewall.sh /usr/local/bin/init-firewall.sh

# Install uv for claude user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/claude/.local/bin:${PATH}"

# Configure shell aliases for modern CLI tools
RUN echo 'alias cat="bat"' >> ~/.zshrc \
    && echo 'alias find="fd"' >> ~/.zshrc \
    && echo 'alias grep="rg"' >> ~/.zshrc \
    && echo 'export EDITOR=vim' >> ~/.zshrc \
    && echo 'export VISUAL=vim' >> ~/.zshrc

# Copy same aliases to bashrc for bash users
RUN echo 'alias cat="bat"' >> ~/.bashrc \
    && echo 'alias find="fd"' >> ~/.bashrc \
    && echo 'alias grep="rg"' >> ~/.bashrc \
    && echo 'export EDITOR=vim' >> ~/.bashrc \
    && echo 'export VISUAL=vim' >> ~/.bashrc

# Set working directory to workspace
WORKDIR /workspace

# Default command: start zsh shell
CMD ["/bin/zsh"]
