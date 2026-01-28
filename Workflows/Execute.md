# Execute Task Workflow

Send tasks to the Autonomous Claude Sandbox for isolated execution.

## When to Use

- Delegate long-running tasks to isolated container
- Execute code that needs different permissions
- Run parallel tasks without blocking main agent
- Isolate potentially destructive operations

## Prerequisites

- Deployed sandbox worker (see `Setup.md`)
- `SERVER_AUTH_TOKEN` for API authentication
- Worker URL (e.g., `https://your-worker.workers.dev`)

---

## Quick Execute (Tool)

For programmatic execution, use the deterministic tool:

```bash
./Tools/execute-task.sh "https://YOUR-WORKER.workers.dev" "YOUR_AUTH_TOKEN" "Your task description here"
```

**Output:**
```json
{
  "success": true,
  "taskId": "uuid",
  "stdout": "Task output...",
  "stderr": "",
  "execution_time_ms": 12500
}
```

---

## Step-by-Step Execution

### Step 1: Prepare the Task

Define a clear, self-contained task description:

```
Good: "Create a Python script that calculates prime numbers up to 1000 and save it to primes.py"

Bad: "Fix the code" (lacks context - sandbox has no access to your local files)
```

**Task Guidelines:**
- Be specific and self-contained
- Include all necessary context
- Specify expected outputs
- Set appropriate timeout for complexity

### Step 2: Execute via API

```bash
curl -X POST https://YOUR-WORKER.workers.dev/execute \
  -H "Authorization: Bearer YOUR_SERVER_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Your task description here",
    "timeout": 300000
  }'
```

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `task` | Yes | - | Task description for Claude |
| `timeout` | No | 300000 | Timeout in milliseconds (max 10 min) |

### Step 3: Handle Response

**Success Response:**
```json
{
  "taskId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "success": true,
  "stdout": "Task completed successfully...",
  "stderr": "",
  "output": "Task completed successfully..."
}
```

**Error Response:**
```json
{
  "error": "Task execution failed",
  "details": "Error message here"
}
```

### Step 4: Retrieve Results (Optional)

For stored results:

```bash
curl https://YOUR-WORKER.workers.dev/tasks/TASK_ID/result \
  -H "Authorization: Bearer YOUR_SERVER_AUTH_TOKEN"
```

---

## Timeout Guidelines

| Task Complexity | Recommended Timeout |
|-----------------|---------------------|
| Simple query | 30000 (30s) |
| Code generation | 60000 (1 min) |
| Multi-file task | 180000 (3 min) |
| Complex analysis | 300000 (5 min) |

---

## Error Handling

| Error Code | Meaning | Action |
|------------|---------|--------|
| 400 | Missing task | Add task to request body |
| 401 | Invalid token | Check SERVER_AUTH_TOKEN |
| 408 | Timeout | Increase timeout or simplify task |
| 500 | Execution failed | Check task description, review logs |

---

## Example Use Cases

### 1. Code Generation

```bash
./Tools/execute-task.sh "$SANDBOX_URL" "$AUTH_TOKEN" \
  "Write a TypeScript function that validates email addresses using regex. Include JSDoc comments and export the function."
```

### 2. Data Analysis

```bash
./Tools/execute-task.sh "$SANDBOX_URL" "$AUTH_TOKEN" \
  "Analyze the following JSON data and provide a summary: {\"users\": 150, \"active\": 89, \"churned\": 12}"
```

### 3. Code Review

```bash
./Tools/execute-task.sh "$SANDBOX_URL" "$AUTH_TOKEN" \
  "Review this code for security issues: function login(user, pass) { db.query('SELECT * FROM users WHERE name=' + user) }"
```

### 4. Documentation

```bash
./Tools/execute-task.sh "$SANDBOX_URL" "$AUTH_TOKEN" \
  "Generate API documentation in markdown format for a REST endpoint: POST /users - creates a new user with name and email fields"
```

---

## Best Practices

1. **Be Explicit**: Sandbox has no context from your local environment
2. **Set Timeouts**: Match timeout to task complexity
3. **Handle Errors**: Always check response for success/error
4. **Use Tool Script**: Prefer `execute-task.sh` for JSON output
5. **Store Credentials**: Use environment variables, not hardcoded tokens

---

## Environment Variables

For convenience, set these in your shell:

```bash
export SANDBOX_URL="https://your-worker.workers.dev"
export SANDBOX_AUTH_TOKEN="your-server-auth-token"
```

Then execute:

```bash
./Tools/execute-task.sh "$SANDBOX_URL" "$SANDBOX_AUTH_TOKEN" "Your task"
```
