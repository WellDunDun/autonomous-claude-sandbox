#!/bin/bash
# Check all prerequisites for Cloudflare Sandbox deployment
# Output: JSON with pass/fail for each requirement
# Exit: 0 if all pass, 1 if any fail

set -e

check_command() {
    if command -v "$1" &> /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

check_docker_running() {
    if docker info &> /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

check_wrangler_auth() {
    if npx wrangler whoami &> /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

get_node_version() {
    if command -v node &> /dev/null; then
        node --version | sed 's/v//'
    else
        echo "0.0.0"
    fi
}

# Run checks
NODE_EXISTS=$(check_command node)
NPM_EXISTS=$(check_command npm)
DOCKER_EXISTS=$(check_command docker)
WRANGLER_EXISTS=$(check_command wrangler)
OPENSSL_EXISTS=$(check_command openssl)
CLAUDE_EXISTS=$(check_command claude)
DOCKER_RUNNING=$(check_docker_running)
WRANGLER_AUTH=$(check_wrangler_auth)
NODE_VERSION=$(get_node_version)

# Check Node version >= 18
NODE_OK="false"
if [[ "$NODE_EXISTS" == "true" ]]; then
    MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)
    if [[ "$MAJOR_VERSION" -ge 18 ]]; then
        NODE_OK="true"
    fi
fi

# Determine overall status
ALL_PASS="true"
ISSUES=()

if [[ "$NODE_OK" != "true" ]]; then
    ALL_PASS="false"
    ISSUES+=("Node.js 18+ required (found: $NODE_VERSION)")
fi
if [[ "$DOCKER_EXISTS" != "true" ]]; then
    ALL_PASS="false"
    ISSUES+=("Docker not installed")
fi
if [[ "$DOCKER_RUNNING" != "true" ]]; then
    ALL_PASS="false"
    ISSUES+=("Docker not running")
fi
if [[ "$WRANGLER_AUTH" != "true" ]]; then
    ALL_PASS="false"
    ISSUES+=("Wrangler not authenticated (run: npx wrangler login)")
fi
if [[ "$CLAUDE_EXISTS" != "true" ]]; then
    ALL_PASS="false"
    ISSUES+=("Claude CLI not installed")
fi

# Build issues JSON array
ISSUES_JSON="[]"
if [[ ${#ISSUES[@]} -gt 0 ]]; then
    ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
fi

# Output JSON
cat <<EOF
{
  "success": $ALL_PASS,
  "checks": {
    "node": {
      "installed": $NODE_EXISTS,
      "version": "$NODE_VERSION",
      "meets_requirement": $NODE_OK
    },
    "npm": {
      "installed": $NPM_EXISTS
    },
    "docker": {
      "installed": $DOCKER_EXISTS,
      "running": $DOCKER_RUNNING
    },
    "wrangler": {
      "installed": $WRANGLER_EXISTS,
      "authenticated": $WRANGLER_AUTH
    },
    "claude": {
      "installed": $CLAUDE_EXISTS
    },
    "openssl": {
      "installed": $OPENSSL_EXISTS
    }
  },
  "issues": $ISSUES_JSON
}
EOF

# Exit with appropriate code
if [[ "$ALL_PASS" == "true" ]]; then
    exit 0
else
    exit 1
fi
