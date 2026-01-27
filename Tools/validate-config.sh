#!/bin/bash
# Validate Cloudflare Sandbox configuration files
# Output: JSON with validation results
# Exit: 0 if valid, 1 if issues found

set -e

# Default to current directory
PROJECT_DIR="${1:-.}"

check_file_exists() {
    if [[ -f "$1" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

ISSUES=()
WARNINGS=()

# Check required files
DOCKERFILE_EXISTS=$(check_file_exists "$PROJECT_DIR/Dockerfile")
WRANGLER_EXISTS=$(check_file_exists "$PROJECT_DIR/wrangler.jsonc")
WRANGLER_JSON_EXISTS=$(check_file_exists "$PROJECT_DIR/wrangler.json")
INDEX_EXISTS=$(check_file_exists "$PROJECT_DIR/src/index.ts")
PACKAGE_EXISTS=$(check_file_exists "$PROJECT_DIR/package.json")

# Use wrangler.json if wrangler.jsonc doesn't exist
if [[ "$WRANGLER_EXISTS" == "false" && "$WRANGLER_JSON_EXISTS" == "true" ]]; then
    WRANGLER_FILE="$PROJECT_DIR/wrangler.json"
    WRANGLER_EXISTS="true"
else
    WRANGLER_FILE="$PROJECT_DIR/wrangler.jsonc"
fi

# Validate Dockerfile
DOCKERFILE_VALID="false"
DOCKERFILE_BASE_IMAGE=""
if [[ "$DOCKERFILE_EXISTS" == "true" ]]; then
    DOCKERFILE_BASE_IMAGE=$(grep -E "^FROM" "$PROJECT_DIR/Dockerfile" | head -1 | awk '{print $2}' || echo "")
    if [[ "$DOCKERFILE_BASE_IMAGE" == *"cloudflare/sandbox"* ]]; then
        DOCKERFILE_VALID="true"
    else
        ISSUES+=("Dockerfile must use cloudflare/sandbox base image (found: $DOCKERFILE_BASE_IMAGE)")
    fi
else
    ISSUES+=("Dockerfile not found")
fi

# Validate wrangler config
WRANGLER_VALID="false"
HAS_CONTAINERS="false"
HAS_DURABLE_OBJECTS="false"
HAS_MIGRATIONS="false"
ACCOUNT_ID=""

if [[ "$WRANGLER_EXISTS" == "true" ]]; then
    # Remove comments for JSON parsing (jsonc -> json)
    WRANGLER_CONTENT=$(sed 's|//.*||g' "$WRANGLER_FILE" | tr -d '\n')

    # Check for required sections using grep (more portable than jq for jsonc)
    if grep -q '"containers"' "$WRANGLER_FILE"; then
        HAS_CONTAINERS="true"
    else
        ISSUES+=("wrangler.jsonc missing 'containers' section")
    fi

    if grep -q '"durable_objects"' "$WRANGLER_FILE"; then
        HAS_DURABLE_OBJECTS="true"
    else
        ISSUES+=("wrangler.jsonc missing 'durable_objects' section")
    fi

    if grep -q '"migrations"' "$WRANGLER_FILE"; then
        HAS_MIGRATIONS="true"
    else
        ISSUES+=("wrangler.jsonc missing 'migrations' section")
    fi

    # Check account_id
    ACCOUNT_ID=$(grep -o '"account_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$WRANGLER_FILE" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
    if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "YOUR_CLOUDFLARE_ACCOUNT_ID" ]]; then
        ISSUES+=("wrangler.jsonc needs valid account_id")
    fi

    if [[ "$HAS_CONTAINERS" == "true" && "$HAS_DURABLE_OBJECTS" == "true" && "$HAS_MIGRATIONS" == "true" ]]; then
        WRANGLER_VALID="true"
    fi
else
    ISSUES+=("wrangler.jsonc not found")
fi

# Validate index.ts
INDEX_VALID="false"
HAS_GETSANDBOX="false"
HAS_EXPORT_SANDBOX="false"
HAS_PERMISSION_MODE="false"

if [[ "$INDEX_EXISTS" == "true" ]]; then
    if grep -q "getSandbox" "$PROJECT_DIR/src/index.ts"; then
        HAS_GETSANDBOX="true"
    else
        ISSUES+=("src/index.ts should use getSandbox() API")
    fi

    if grep -q 'export.*Sandbox.*from.*@cloudflare/sandbox' "$PROJECT_DIR/src/index.ts"; then
        HAS_EXPORT_SANDBOX="true"
    else
        ISSUES+=("src/index.ts must export Sandbox class")
    fi

    if grep -q 'dangerously-skip-permissions' "$PROJECT_DIR/src/index.ts"; then
        ISSUES+=("src/index.ts uses --dangerously-skip-permissions (use --permission-mode instead)")
    fi

    if grep -q 'permission-mode' "$PROJECT_DIR/src/index.ts"; then
        HAS_PERMISSION_MODE="true"
    else
        WARNINGS+=("Consider using --permission-mode acceptEdits for Claude CLI")
    fi

    if [[ "$HAS_GETSANDBOX" == "true" && "$HAS_EXPORT_SANDBOX" == "true" ]]; then
        INDEX_VALID="true"
    fi
else
    ISSUES+=("src/index.ts not found")
fi

# Determine overall status
ALL_VALID="true"
if [[ ${#ISSUES[@]} -gt 0 ]]; then
    ALL_VALID="false"
fi

# Build JSON arrays
ISSUES_JSON="[]"
WARNINGS_JSON="[]"
if [[ ${#ISSUES[@]} -gt 0 ]]; then
    ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
fi
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
fi

# Output JSON
cat <<EOF
{
  "success": $ALL_VALID,
  "project_dir": "$PROJECT_DIR",
  "files": {
    "dockerfile": {
      "exists": $DOCKERFILE_EXISTS,
      "valid": $DOCKERFILE_VALID,
      "base_image": "$DOCKERFILE_BASE_IMAGE"
    },
    "wrangler": {
      "exists": $WRANGLER_EXISTS,
      "valid": $WRANGLER_VALID,
      "has_containers": $HAS_CONTAINERS,
      "has_durable_objects": $HAS_DURABLE_OBJECTS,
      "has_migrations": $HAS_MIGRATIONS,
      "account_id_set": $(if [[ -n "$ACCOUNT_ID" && "$ACCOUNT_ID" != "YOUR_CLOUDFLARE_ACCOUNT_ID" ]]; then echo "true"; else echo "false"; fi)
    },
    "index_ts": {
      "exists": $INDEX_EXISTS,
      "valid": $INDEX_VALID,
      "uses_getSandbox": $HAS_GETSANDBOX,
      "exports_Sandbox": $HAS_EXPORT_SANDBOX,
      "uses_permission_mode": $HAS_PERMISSION_MODE
    },
    "package_json": {
      "exists": $PACKAGE_EXISTS
    }
  },
  "issues": $ISSUES_JSON,
  "warnings": $WARNINGS_JSON
}
EOF

# Exit with appropriate code
if [[ "$ALL_VALID" == "true" ]]; then
    exit 0
else
    exit 1
fi
