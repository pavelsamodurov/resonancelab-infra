#!/usr/bin/env bash
# Deploy AI Gateway — interactive tag picker
# Usage: ./scripts/deploy.sh [environment]
#
# Requires: gh CLI authenticated with read:packages scope, jq
# Optional: fzf (for fuzzy search UI)
#
# gh auth login uses browser OAuth which does NOT include read:packages by default.
# If you get 404, re-authenticate with the required scope:
#
#   gh auth login --scopes read:packages
#   (or) gh auth refresh --scopes read:packages

set -euo pipefail

OWNER="pavelsamodurov"
PACKAGE="ai-gateway"
WORKFLOW="deploy-ai-gateway.yaml"
TAG_COUNT=20

# ── colours ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── checks ────────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  echo -e "${RED}Error:${RESET} gh CLI is not installed. Install: https://cli.github.com"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error:${RESET} jq is not installed. Install: brew install jq"
  exit 1
fi

# ── fetch tags ────────────────────────────────────────────────────────────────
echo -e "\n${DIM}Fetching tags from GHCR...${RESET}"

VERSIONS_JSON=$(gh api "/users/${OWNER}/packages/container/${PACKAGE}/versions" \
  --jq '[
    .[] |
    select(.metadata.container.tags | length > 0) |
    select(.metadata.container.tags | any(. != "latest")) |
    {
      tag:     (.metadata.container.tags | map(select(. != "latest")) | first),
      created: .created_at
    }
  ] | .[0:'"${TAG_COUNT}"']')

if [[ -z "$VERSIONS_JSON" || "$VERSIONS_JSON" == "[]" ]]; then
  echo -e "${RED}Error:${RESET} No tags found in registry."
  exit 1
fi

# Format: "sha-abc1234  (2026-04-24 11:55 UTC)"
FORMATTED=$(echo "$VERSIONS_JSON" | jq -r \
  '.[] | "\(.tag)  \u001b[2m(\(.created | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M UTC")))\u001b[0m"' \
  2>/dev/null || \
  echo "$VERSIONS_JSON" | jq -r '.[] | "\(.tag)  (\(.created))"')

# ── pick tag ──────────────────────────────────────────────────────────────────
echo ""

if command -v fzf &>/dev/null; then
  echo -e "${BOLD}Select image tag${RESET} ${DIM}(↑↓ navigate, / search, Enter confirm)${RESET}"
  echo ""
  CHOSEN_LINE=$(echo -e "$FORMATTED" | fzf \
    --ansi \
    --no-sort \
    --prompt="  tag > " \
    --pointer="▶" \
    --height=40% \
    --border=rounded \
    --info=hidden)
else
  echo -e "${BOLD}Available tags:${RESET}"
  echo ""
  IFS=$'\n' read -rd '' -a LINES <<<"$FORMATTED" || true
  for i in "${!LINES[@]}"; do
    printf "  ${CYAN}%2d)${RESET}  %b\n" $((i + 1)) "${LINES[$i]}"
  done
  echo ""
  read -rp "Select tag number: " CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#LINES[@]} )); then
    echo -e "${RED}Invalid selection.${RESET}"
    exit 1
  fi
  CHOSEN_LINE="${LINES[$((CHOICE - 1))]}"
fi

IMAGE_TAG=$(echo "$CHOSEN_LINE" | awk '{print $1}')

if [[ -z "$IMAGE_TAG" ]]; then
  echo -e "${RED}No tag selected.${RESET}"
  exit 1
fi

# ── pick environment ──────────────────────────────────────────────────────────
echo ""
if [[ -n "${1:-}" ]]; then
  ENVIRONMENT="$1"
else
  echo -e "${BOLD}Select environment:${RESET}"
  echo ""
  if command -v fzf &>/dev/null; then
    ENVIRONMENT=$(printf "dev\nprod" | fzf \
      --ansi \
      --prompt="  env > " \
      --pointer="▶" \
      --height=20% \
      --border=rounded \
      --info=hidden)
  else
    select env in dev prod; do
      ENVIRONMENT="$env"
      break
    done
  fi
fi

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo -e "${RED}Invalid environment: ${ENVIRONMENT}${RESET}"
  exit 1
fi

# ── confirm ───────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${DIM}tag:${RESET}  ${BOLD}${IMAGE_TAG}${RESET}"
echo -e "  ${DIM}env:${RESET}  ${BOLD}${ENVIRONMENT}${RESET}"
echo ""
read -rp "Deploy? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${DIM}Aborted.${RESET}"
  exit 0
fi

# ── trigger workflow ──────────────────────────────────────────────────────────
echo ""
echo -e "${DIM}Triggering ${WORKFLOW}...${RESET}"

gh workflow run "$WORKFLOW" \
  --repo "${OWNER}/resonancelab-infra" \
  --field "image_tag=${IMAGE_TAG}" \
  --field "environment=${ENVIRONMENT}"

echo ""
echo -e "${GREEN}✓${RESET} Workflow triggered: ${BOLD}${IMAGE_TAG}${RESET} → ${BOLD}${ENVIRONMENT}${RESET}"
echo ""
echo -e "${DIM}Track run:${RESET}"
echo -e "  gh run list --repo ${OWNER}/resonancelab-infra --workflow=${WORKFLOW} --limit=1"
echo -e "  gh run watch --repo ${OWNER}/resonancelab-infra"
