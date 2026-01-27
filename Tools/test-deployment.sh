#!/bin/bash
# Test a Cloudflare Sandbox deployment
# Usage: ./test-deployment.sh <worker-url> <auth-token>
# Output: JSON with test results
# Exit: 0 if all tests pass, 1 if any fail

set -e

WORKER_URL="${1:-}"
AUTH_TOKEN="${2:-}"

if [[ -z "$WORKER_URL" ]]; then
    echo '{"success": false, "error": "Usage: ./test-deployment.sh <worker-url> <auth-token>"}'
    exit 1
fi

# Remove trailing slash
WORKER_URL="${WORKER_URL%/}"

TESTS_PASSED=0
TESTS_FAILED=0
RESULTS=()

# Test 1: Health check
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/health" 2>/dev/null || echo -e "\n000")
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | head -n -1)
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 1)

HEALTH_SUCCESS="false"
HEALTH_STATUS=""
if [[ "$HEALTH_CODE" == "200" ]]; then
    HEALTH_SUCCESS="true"
    HEALTH_STATUS=$(echo "$HEALTH_BODY" | jq -r '.status // "unknown"' 2>/dev/null || echo "parse_error")
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

# Test 2: Auth check (should fail without token)
UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/execute" \
    -H "Content-Type: application/json" \
    -d '{"task": "test"}' 2>/dev/null || echo -e "\n000")
UNAUTH_CODE=$(echo "$UNAUTH_RESPONSE" | tail -n 1)

AUTH_REQUIRED="false"
if [[ "$UNAUTH_CODE" == "401" ]]; then
    AUTH_REQUIRED="true"
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

# Test 3: Execute task (if token provided)
EXEC_SUCCESS="false"
EXEC_OUTPUT=""
EXEC_ERROR=""
EXEC_SKIPPED="true"

if [[ -n "$AUTH_TOKEN" ]]; then
    EXEC_SKIPPED="false"
    EXEC_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/execute" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"task": "What is 2 + 2? Respond with just the number.", "timeout": 60000}' 2>/dev/null || echo -e "\n000")
    EXEC_BODY=$(echo "$EXEC_RESPONSE" | head -n -1)
    EXEC_CODE=$(echo "$EXEC_RESPONSE" | tail -n 1)

    if [[ "$EXEC_CODE" == "200" ]]; then
        EXEC_SUCCESS=$(echo "$EXEC_BODY" | jq -r '.success // false' 2>/dev/null || echo "false")
        EXEC_OUTPUT=$(echo "$EXEC_BODY" | jq -r '.output // .stdout // ""' 2>/dev/null || echo "")

        # Check if output contains "4"
        if [[ "$EXEC_SUCCESS" == "true" && "$EXEC_OUTPUT" == *"4"* ]]; then
            ((TESTS_PASSED++))
        else
            EXEC_ERROR="Unexpected output: $EXEC_OUTPUT"
            ((TESTS_FAILED++))
        fi
    else
        EXEC_ERROR="HTTP $EXEC_CODE: $EXEC_BODY"
        ((TESTS_FAILED++))
    fi
fi

# Calculate overall success
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
ALL_PASS="false"
if [[ "$TESTS_FAILED" -eq 0 && "$TESTS_PASSED" -gt 0 ]]; then
    ALL_PASS="true"
fi

# Output JSON
cat <<EOF
{
  "success": $ALL_PASS,
  "worker_url": "$WORKER_URL",
  "summary": {
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "total": $TOTAL_TESTS
  },
  "tests": {
    "health_check": {
      "success": $HEALTH_SUCCESS,
      "http_code": $HEALTH_CODE,
      "status": "$HEALTH_STATUS"
    },
    "auth_required": {
      "success": $AUTH_REQUIRED,
      "http_code": $UNAUTH_CODE,
      "description": "Verifies /execute requires authentication"
    },
    "execute_task": {
      "skipped": $EXEC_SKIPPED,
      "success": $EXEC_SUCCESS,
      "output": "$EXEC_OUTPUT",
      "error": "$EXEC_ERROR"
    }
  }
}
EOF

# Exit with appropriate code
if [[ "$ALL_PASS" == "true" ]]; then
    exit 0
else
    exit 1
fi
