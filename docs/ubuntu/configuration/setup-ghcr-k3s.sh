#!/bin/bash
# =============================================
# setup-ghcr-k3s.sh
# Configures k3s to pull private images from GitHub Container Registry (GHCR)
# Usage: ./setup-ghcr-k3s.sh <github_username> <github_pat>
# =============================================

set -e

GITHUB_USERNAME=${1:-}
GITHUB_PAT=${2:-}

# Check parameters
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
  echo "Usage: $0 <github_username> <github_pat>"
  echo "Example: $0 githubuser ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  exit 1
fi

echo "=== GHCR Configuration for k3s ==="
echo "Username : ${GITHUB_USERNAME}"
echo "PAT      : [hidden]"
echo

# Create registries.yaml
echo "Creating /etc/rancher/k3s/registries.yaml ..."

cat > /etc/rancher/k3s/registries.yaml << EOF
mirrors:
  "ghcr.io":
    endpoint:
      - "https://ghcr.io"
configs:
  "ghcr.io":
    auth:
      username: "${GITHUB_USERNAME}"
      password: "${GITHUB_PAT}"
EOF

chmod 600 /etc/rancher/k3s/registries.yaml

echo "registries.yaml created successfully"

# Restart k3s
echo "Restarting k3s service..."
systemctl restart k3s

echo "Waiting for k3s to restart (10 seconds)..."
sleep 10

# Check status
if systemctl is-active --quiet k3s; then
  echo "✅ k3s service is running"
else
  echo "❌ Warning: k3s service failed to start"
  exit 1
fi

echo
echo "========================================"
echo "GHCR configuration completed successfully!"
echo "Username : ${GITHUB_USERNAME}"
echo "You can now pull private images from ghcr.io/${GITHUB_USERNAME}/"
echo "========================================"
