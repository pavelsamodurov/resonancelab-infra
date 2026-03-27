#!/bin/bash
# create-ghcr-secret.sh — non-interactive version

GITHUB_USERNAME=${1:-}
GITHUB_PAT=${2:-}

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
  echo "Usage: $0 <github_username> <github_pat>"
  exit 1
fi

echo "Creating ghcr-pull-secret for user: $GITHUB_USERNAME"

kubectl delete secret ghcr-pull-secret --namespace default 2>/dev/null || true

kubectl create secret docker-registry ghcr-pull-secret \
  --namespace default \
  --docker-server=https://ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_PAT"

if [ $? -eq 0 ]; then
  echo "✅ ghcr-pull-secret created successfully"
else
  echo "❌ Failed to create secret"
fi