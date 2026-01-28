#!/bin/bash
# Execute a task on the Autonomous Claude Sandbox
# Usage: ./execute-task.sh <worker-url> <auth-token> <task> [timeout-ms]
# Output: JSON with task result
# Exit: 0 on success, 1 on error

set -e

WORKER_URL="${1:-}"
AUTH_TOKEN="${2:-}"
TASK="${3:-}"
TIMEOUT="${4:-300000}"

# Validate inputs
if [[ -z "$WORKER_URL" ]] || [[ -z "$AUTH_TOKEN" ]] || [[ -z "$TASK" ]]; then
    cat <<EOF
{
  "success": false,
  "error": "Missing required arguments",
  "usage": "./execute-task.sh <worker-url> <auth-token> <task> [timeout-ms]",
  "example": "./execute-task.sh https://my-worker.workers.dev my-token 'Write a hello world script'"
}
EOF
    exit 1
fi

# Record start time (use seconds - %N not supported on macOS)
START_TIME=$(date +%s)

# Execute the task
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${WORKER_URL}/execute" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"task\": $(echo "$TASK" | jq -R .), \"timeout\": $TIMEOUT}" \
    2>/dev/null)

# Parse response and status code
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# Calculate execution time in seconds
END_TIME=$(date +%s)
EXEC_TIME_SEC=$((END_TIME - START_TIME))
EXEC_TIME=$((EXEC_TIME_SEC * 1000))

# Handle response based on status code
case "$HTTP_CODE" in
    200)
        # Success - add execution time to response
        if echo "$BODY" | jq -e . >/dev/null 2>&1; then
            echo "$BODY" | jq --arg exec_time "$EXEC_TIME" '. + {execution_time_ms: ($exec_time | tonumber)}'
            exit 0
        else
            cat <<EOF
{
  "success": true,
  "raw_response": $(echo "$BODY" | jq -R .),
  "execution_time_ms": $EXEC_TIME
}
EOF
            exit 0
        fi
        ;;
    400)
        cat <<EOF
{
  "success": false,
  "error": "Bad request - task is required",
  "http_code": $HTTP_CODE,
  "response": $(echo "$BODY" | jq -R . 2>/dev/null || echo "\"$BODY\"")
}
EOF
        exit 1
        ;;
    401)
        cat <<EOF
{
  "success": false,
  "error": "Unauthorized - check your auth token",
  "http_code": $HTTP_CODE,
  "hint": "Verify SERVER_AUTH_TOKEN matches the deployed secret"
}
EOF
        exit 1
        ;;
    408)
        cat <<EOF
{
  "success": false,
  "error": "Request timeout",
  "http_code": $HTTP_CODE,
  "hint": "Increase timeout or simplify the task",
  "current_timeout_ms": $TIMEOUT
}
EOF
        exit 1
        ;;
    500)
        cat <<EOF
{
  "success": false,
  "error": "Server error - task execution failed",
  "http_code": $HTTP_CODE,
  "response": $(echo "$BODY" | jq -R . 2>/dev/null || echo "\"$BODY\""),
  "hint": "Check worker logs with: npx wrangler tail"
}
EOF
        exit 1
        ;;
    *)
        cat <<EOF
{
  "success": false,
  "error": "Unexpected response",
  "http_code": $HTTP_CODE,
  "response": $(echo "$BODY" | jq -R . 2>/dev/null || echo "\"$BODY\"")
}
EOF
        exit 1
        ;;
esac
