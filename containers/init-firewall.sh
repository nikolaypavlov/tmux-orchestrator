#!/bin/bash
# Firewall initialization for Claude agent containers
# Restricts network access to approved domains only

set -e

# Check if running with necessary capabilities
if ! command -v iptables &> /dev/null; then
    echo "Warning: iptables not available. Firewall not configured."
    exit 0
fi

echo "Initializing firewall for Claude agent container..."

# Allowed domains list
ALLOWED_DOMAINS=(
    # GitHub
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "codeload.github.com"

    # Anthropic API
    "api.anthropic.com"
    "claude.ai"

    # HuggingFace
    "huggingface.co"
    "cdn-lfs.huggingface.co"
    "cdn-lfs-us-1.huggingface.co"
    "cdn-lfs.hf.co"

    # GitLab
    "gitlab.com"
    "gitlab-assets.gitlab.io"

    # Python packages
    "pypi.org"
    "files.pythonhosted.org"
    "pypi.python.org"

    # Node.js / npm
    "registry.npmjs.org"
    "registry.yarnpkg.com"
    "nodejs.org"

    # Essential services
    "archive.ubuntu.com"
    "security.ubuntu.com"
    "ports.ubuntu.com"
)

# DNS servers
DNS_SERVERS=(
    "1.1.1.1"      # Cloudflare
    "1.0.0.1"      # Cloudflare
    "8.8.8.8"      # Google
    "8.8.4.4"      # Google
)

# Create ipset for allowed IPs (if ipset is available)
if command -v ipset &> /dev/null; then
    # Clean up existing ipset if it exists
    ipset destroy allowed-ips 2>/dev/null || true

    # Create new ipset
    ipset create allowed-ips hash:ip timeout 3600

    # Resolve domains and add to ipset
    for domain in "${ALLOWED_DOMAINS[@]}"; do
        echo "Resolving $domain..."
        # Get all IP addresses for the domain
        ips=$(dig +short "$domain" A 2>/dev/null || host "$domain" 2>/dev/null | grep "has address" | awk '{print $NF}')
        for ip in $ips; do
            # Validate IP format
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                ipset add allowed-ips "$ip" 2>/dev/null || true
                echo "  Added $ip"
            fi
        done
    done

    # Add DNS servers to allowed list
    for dns in "${DNS_SERVERS[@]}"; do
        ipset add allowed-ips "$dns" 2>/dev/null || true
    done

    echo "Configuring iptables rules..."

    # Flush existing rules
    iptables -F OUTPUT 2>/dev/null || true

    # Default policy: DROP outgoing connections
    iptables -P OUTPUT DROP 2>/dev/null || true

    # Allow loopback
    iptables -A OUTPUT -o lo -j ACCEPT 2>/dev/null || true

    # Allow established connections
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true

    # Allow DNS (UDP port 53)
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || true

    # Allow connections to allowed IPs
    iptables -A OUTPUT -m set --match-set allowed-ips dst -j ACCEPT 2>/dev/null || true

    # Log dropped packets (optional, for debugging)
    # iptables -A OUTPUT -j LOG --log-prefix "FW-DROP: " --log-level 4 2>/dev/null || true

    echo "Firewall configured successfully!"
    echo "Allowed domains: ${#ALLOWED_DOMAINS[@]}"
    echo "Allowed IPs in set: $(ipset list allowed-ips | grep -c "^[0-9]")"
else
    echo "Warning: ipset not available. Firewall not configured."
    echo "Container will have unrestricted network access."
fi

exit 0
