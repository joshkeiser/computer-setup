#!/bin/bash
# Push an SSH public key from 1Password to all running LXCs and VMs on a Proxmox host.
#
# Usage:
#   ./scripts/push-ssh-key.sh <proxmox-host> [op-item-name]
#
# Examples:
#   ./scripts/push-ssh-key.sh 10.0.69.69
#   ./scripts/push-ssh-key.sh 10.0.69.69 my-ssh-key
#
# Requirements:
#   - op (1Password CLI), authenticated
#   - SSH access to the Proxmox host as root
#   - LXCs: nothing extra (uses pct exec)
#   - VMs: qemu-guest-agent installed and running inside each VM

set -euo pipefail

PROXMOX_HOST="${1:?Usage: $0 <proxmox-host> [op-item-name]}"
OP_ITEM="${2:-proxmox}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_info "Reading public key from 1Password (item: $OP_ITEM)..."
PUB_KEY=$(op read "op://Private/$OP_ITEM/public key")

# Base64-encode so the key passes through the SSH connection without quoting issues
PUB_KEY_B64=$(printf '%s' "$PUB_KEY" | base64 | tr -d '\n')

log_info "Connecting to $PROXMOX_HOST..."

ssh "root@$PROXMOX_HOST" /bin/bash <<REMOTE
set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PUB_KEY=\$(printf '%s' "$PUB_KEY_B64" | base64 -d)

inject_key_cmd() {
    # Idempotent — only appends if the key isn't already present
    cat <<'CMD'
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        grep -qxF "\$PUB_KEY" /root/.ssh/authorized_keys 2>/dev/null \
            || printf '%s\n' "\$PUB_KEY" >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
CMD
}

echo ""
echo "=== LXC Containers ==="
pct list 2>/dev/null | awk 'NR>1 && \$2=="running" {print \$1}' | while read -r id; do
    name=\$(pct config "\$id" 2>/dev/null | awk -F': ' '/^hostname/{print \$2}')
    printf "  LXC \$id (\$name)... "
    if pct exec "\$id" -- bash -c "
        mkdir -p /root/.ssh && chmod 700 /root/.ssh
        grep -qxF '\$PUB_KEY' /root/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '\$PUB_KEY' >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    " 2>/dev/null; then
        echo -e "\${GREEN}done\${NC}"
    else
        echo -e "\${RED}FAILED\${NC}"
    fi
done

echo ""
echo "=== Virtual Machines ==="
qm list 2>/dev/null | awk 'NR>1 && \$3=="running" {print \$1}' | while read -r id; do
    name=\$(qm config "\$id" 2>/dev/null | awk -F': ' '/^name/{print \$2}')
    printf "  VM \$id (\$name)... "

    # Get first non-loopback IPv4 via qemu guest agent
    ip=\$(qm agent "\$id" network-get-interfaces 2>/dev/null \
        | grep -oP '(?<="ip-address": ")[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
        | grep -v '^127\.' | head -1 || true)

    if [ -z "\$ip" ]; then
        echo -e "\${YELLOW}skipped\${NC} (no guest agent or no IP — install qemu-guest-agent inside the VM)"
        continue
    fi

    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "root@\$ip" "
        mkdir -p /root/.ssh && chmod 700 /root/.ssh
        grep -qxF '\$PUB_KEY' /root/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '\$PUB_KEY' >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    " 2>/dev/null; then
        echo -e "\${GREEN}done\${NC} (\$ip)"
    else
        echo -e "\${RED}FAILED\${NC} (\$ip)"
    fi
done

echo ""
REMOTE

log_info "Done."
