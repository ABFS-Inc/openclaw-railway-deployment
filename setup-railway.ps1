# setup-railway.ps1 — Automated Railway project setup for OpenClaw
# Usage: .\setup-railway.ps1
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

$ErrorActionPreference = "Stop"
$PORT = if ($env:PORT) { $env:PORT } else { "8080" }

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "[ERR]   $msg" -ForegroundColor Red }

# ── Pre-checks ───────────────────────────────────────────────────────
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Err "Railway CLI not found. Install: https://docs.railway.com/cli"
    exit 1
}

Write-Info "Checking Railway authentication..."
$whoami = railway whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Err "Not logged in. Run: railway login"
    exit 1
}
Write-Ok "Authenticated as $whoami"

# ── Link project ─────────────────────────────────────────────────────
Write-Info "Checking Railway project link..."
$status = railway status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Info "No project linked. Running interactive link..."
    railway link
}
Write-Ok "Project linked"

# ── Set variables ────────────────────────────────────────────────────
Write-Info "Setting PORT=$PORT..."
railway variables --set "PORT=$PORT" 2>&1 | Out-Null
Write-Ok "Variables set"

# ── Generate domain with correct port ────────────────────────────────
Write-Info "Generating Railway domain with target port $PORT..."
$domainOutput = railway domain --port $PORT --json 2>&1 | Out-String

if ($domainOutput -match "Domain is not available") {
    Write-Info "Railway-provided domain already exists."
    Write-Info "If the port was wrong, delete the domain in the dashboard and re-run this script."
    railway domain --json 2>&1
} elseif ($domainOutput -match "domains") {
    Write-Ok "Domain created with target port $PORT"
    Write-Host $domainOutput
} else {
    Write-Info "Domain output: $domainOutput"
}

# ── Deploy ───────────────────────────────────────────────────────────
Write-Info "Deploying service..."
railway up --detach 2>&1
Write-Ok "Deployment triggered! Monitor with: railway logs"

Write-Host ""
Write-Info "Setup complete. Your app will be available at the domain shown above."
Write-Info "The target port is set to $PORT - no manual browser configuration needed."
