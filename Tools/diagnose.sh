#!/bin/bash
# Gather diagnostic information for troubleshooting
# Output: JSON with all relevant system and project info
# Exit: Always 0 (diagnostic tool)

set -e

PROJECT_DIR="${1:-.}"

# Get versions
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
NPM_VERSION=$(npm --version 2>/dev/null || echo "not installed")
DOCKER_VERSION=$(docker --version 2>/dev/null || echo "not installed")
WRANGLER_VERSION=$(npx wrangler --version 2>/dev/null || echo "not installed")
CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "not installed")

# Docker status
DOCKER_RUNNING="false"
DOCKER_INFO=""
if docker info &>/dev/null; then
    DOCKER_RUNNING="true"
    DOCKER_INFO=$(docker info --format '{{json .}}' 2>/dev/null | jq '{ServerVersion, OperatingSystem, Architecture, CPUs: .NCPU, Memory: .MemTotal}' 2>/dev/null || echo '{}')
fi

# Wrangler auth status
WRANGLER_AUTH="false"
WRANGLER_USER=""
if npx wrangler whoami &>/dev/null; then
    WRANGLER_AUTH="true"
    WRANGLER_USER=$(npx wrangler whoami 2>/dev/null | grep -o 'You are logged in with an OAuth Token.*' || echo "authenticated")
fi

# Check for secrets (just existence, not values)
HAS_OAUTH_SECRET="unknown"
HAS_AUTH_SECRET="unknown"

# Recent deployments
DEPLOYMENTS="[]"
if [[ -d "$PROJECT_DIR" ]] && npx wrangler deployments list --config "$PROJECT_DIR/wrangler.jsonc" &>/dev/null 2>&1; then
    DEPLOYMENTS=$(npx wrangler deployments list --config "$PROJECT_DIR/wrangler.jsonc" 2>/dev/null | head -10 | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
fi

# Container status
CONTAINERS="[]"
if npx wrangler containers list &>/dev/null 2>&1; then
    CONTAINERS=$(npx wrangler containers list 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
fi

# Project file checksums (for detecting changes)
DOCKERFILE_HASH=""
WRANGLER_HASH=""
INDEX_HASH=""
if [[ -f "$PROJECT_DIR/Dockerfile" ]]; then
    DOCKERFILE_HASH=$(md5 -q "$PROJECT_DIR/Dockerfile" 2>/dev/null || md5sum "$PROJECT_DIR/Dockerfile" 2>/dev/null | awk '{print $1}' || echo "")
fi
if [[ -f "$PROJECT_DIR/wrangler.jsonc" ]]; then
    WRANGLER_HASH=$(md5 -q "$PROJECT_DIR/wrangler.jsonc" 2>/dev/null || md5sum "$PROJECT_DIR/wrangler.jsonc" 2>/dev/null | awk '{print $1}' || echo "")
fi
if [[ -f "$PROJECT_DIR/src/index.ts" ]]; then
    INDEX_HASH=$(md5 -q "$PROJECT_DIR/src/index.ts" 2>/dev/null || md5sum "$PROJECT_DIR/src/index.ts" 2>/dev/null | awk '{print $1}' || echo "")
fi

# System info
OS_TYPE=$(uname -s)
OS_VERSION=$(uname -r)
ARCH=$(uname -m)

# Output JSON
cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_dir": "$PROJECT_DIR",
  "system": {
    "os": "$OS_TYPE",
    "os_version": "$OS_VERSION",
    "architecture": "$ARCH"
  },
  "versions": {
    "node": "$NODE_VERSION",
    "npm": "$NPM_VERSION",
    "docker": "$DOCKER_VERSION",
    "wrangler": "$WRANGLER_VERSION",
    "claude": "$CLAUDE_VERSION"
  },
  "docker": {
    "running": $DOCKER_RUNNING,
    "info": $DOCKER_INFO
  },
  "wrangler": {
    "authenticated": $WRANGLER_AUTH,
    "user": "$WRANGLER_USER"
  },
  "project_files": {
    "dockerfile_hash": "$DOCKERFILE_HASH",
    "wrangler_hash": "$WRANGLER_HASH",
    "index_hash": "$INDEX_HASH"
  },
  "cloudflare": {
    "deployments": $DEPLOYMENTS,
    "containers": $CONTAINERS
  }
}
EOF

exit 0
