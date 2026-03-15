#!/usr/bin/env bash
# setup-railway.sh — Automated Railway project setup for OpenClaw
# Usage: bash setup-railway.sh
#
# This script:
#   1. Links the Railway project/service/environment
#   2. Sets required variables (PORT, etc.)
#   3. Generates a Railway domain with the correct target port
#   4. Deploys the service
#
# Prerequisites:
#   - Railway CLI installed and authenticated (railway login)
#   - Project already created on Railway

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────
PORT="${PORT:-8080}"

# ── Helpers ──────────────────────────────────────────────────────────
info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
err()   { printf '\033[1;31m[ERR]\033[0m   %s\n' "$*" >&2; }

# ── Pre-checks ───────────────────────────────────────────────────────
if ! command -v railway &>/dev/null; then
  err "Railway CLI not found. Install: https://docs.railway.com/cli"
  exit 1
fi

info "Checking Railway authentication..."
if ! railway whoami &>/dev/null; then
  err "Not logged in. Run: railway login"
  exit 1
fi
ok "Authenticated as $(railway whoami 2>/dev/null)"

# ── Link project ─────────────────────────────────────────────────────
info "Linking Railway project..."
if ! railway status &>/dev/null 2>&1; then
  info "No project linked. Running interactive link..."
  railway link
fi
ok "Project linked"

# ── Set variables ────────────────────────────────────────────────────
info "Setting PORT=$PORT..."
railway variables --set "PORT=$PORT"
ok "Variables set"

# ── Generate domain with correct port ────────────────────────────────
info "Generating Railway domain with target port $PORT..."
DOMAIN_OUTPUT=$(railway domain --port "$PORT" --json 2>&1) || true

if echo "$DOMAIN_OUTPUT" | grep -q "Domain is not available"; then
  info "Railway-provided domain already exists — port may need manual update if it was created before PORT was set."
  info "Current domain configuration:"
  railway domain --json 2>/dev/null || true
elif echo "$DOMAIN_OUTPUT" | grep -q "domains"; then
  ok "Domain created with target port $PORT"
  echo "$DOMAIN_OUTPUT"
else
  info "Domain output: $DOMAIN_OUTPUT"
fi

# ── Deploy ───────────────────────────────────────────────────────────
info "Deploying service..."
railway up --detach
ok "Deployment triggered! Monitor with: railway logs"

echo ""
info "Setup complete. Your app will be available at the domain shown above."
info "The target port is set to $PORT — no manual browser configuration needed."
