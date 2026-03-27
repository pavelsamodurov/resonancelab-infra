#!/bin/bash
# =============================================
# setup-k3s-external.sh
# Creates external kubeconfig for CI/CD (GitHub Actions)
# Usage: ./setup-k3s-external.sh <public_host> [port]
# =============================================

PUBLIC_HOST=${1:-}
PORT=${2:-6443}

if [ -z "$PUBLIC_HOST" ]; then
  echo "Usage: $0 <public_host> [port]"
  exit 1
fi

echo "=== k3s External Access Setup ==="
echo "Public host : $PUBLIC_HOST"
echo "Port        : $PORT"
echo

K3S_CONFIG="/etc/rancher/k3s/k3s.yaml"
EXTERNAL_CONFIG="$HOME/k3s-external-config.yaml"

if [ ! -f "$K3S_CONFIG" ]; then
  echo "❌ Error: k3s config not found at $K3S_CONFIG"
  exit 1
fi

# Create copy and update server address
cp "$K3S_CONFIG" "$EXTERNAL_CONFIG"
chmod 600 "$EXTERNAL_CONFIG"

kubectl --kubeconfig "$EXTERNAL_CONFIG" config set-cluster default \
  --server="https://${PUBLIC_HOST}:${PORT}"

if [ $? -eq 0 ]; then
  echo "✅ External kubeconfig successfully created!"
  echo "   Location : $EXTERNAL_CONFIG"
  echo
  echo "Next steps:"
  echo "   1. cat $EXTERNAL_CONFIG"
  echo "   2. Copy the entire content"
  echo "   3. Paste it into GitHub Secret 'KUBECONFIG'"
else
  echo "❌ Failed to update kubeconfig"
  exit 1
fi