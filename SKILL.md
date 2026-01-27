---
name: cloudflare-sandbox
description: Deploy Claude Code on Cloudflare Sandboxes. Run autonomous AI coding tasks in isolated containers via a simple API.
---

# Cloudflare Sandbox Skill

Deploy Claude Code on Cloudflare Sandbox containers for autonomous AI task execution.

## When to Use This Skill

Activate when you see these patterns:

- "Setup cloudflare sandbox"
- "Deploy claude sandbox"
- "Create sandbox worker"
- "Set up Claude Code on Cloudflare"
- "Deploy Claude on containers"
- "Autonomous AI task execution"

## Workflow Routing

Route to the appropriate workflow based on the request:

- Set up new Cloudflare Sandbox deployment → `Workflows/Setup.md`
- Deploy/update existing deployment → `Workflows/Deploy.md`
- Troubleshoot issues → `Workflows/Troubleshoot.md`

---

## Deterministic Tools

These scripts output JSON and use proper exit codes for AI agent consumption.

| Tool | Purpose | Usage |
|------|---------|-------|
| `Tools/check-prerequisites.sh` | Verify all requirements | `./Tools/check-prerequisites.sh` |
| `Tools/validate-config.sh` | Check project config | `./Tools/validate-config.sh [project-dir]` |
| `Tools/test-deployment.sh` | Test live deployment | `./Tools/test-deployment.sh <url> [token]` |
| `Tools/diagnose.sh` | Gather troubleshooting info | `./Tools/diagnose.sh [project-dir]` |
| `Tools/generate-token.sh` | Generate auth token | `./Tools/generate-token.sh` |

### Example: Check Prerequisites

```bash
./Tools/check-prerequisites.sh | jq .
```

Output:
```json
{
  "success": true,
  "checks": {
    "node": { "installed": true, "version": "20.10.0", "meets_requirement": true },
    "docker": { "installed": true, "running": true },
    "wrangler": { "installed": true, "authenticated": true }
  },
  "issues": []
}
```

### Example: Validate Config

```bash
./Tools/validate-config.sh /path/to/project | jq .
```

### Example: Test Deployment

```bash
./Tools/test-deployment.sh https://my-worker.workers.dev my-auth-token | jq .
```

---

## Quick Start

### Prerequisites

- Cloudflare account with Workers Paid plan ($5/month)
- Docker Desktop running locally
- Node.js 18+
- Claude MAX subscription

### Installation

```bash
# Clone reference implementation
git clone https://github.com/WellDunDun/claude-code-sandbox.git
cd claude-code-sandbox
npm install

# Authenticate with Cloudflare
npx wrangler login

# Create R2 bucket
npx wrangler r2 bucket create claude-results

# Set secrets
claude setup-token
npx wrangler secret put CLAUDE_CODE_OAUTH_TOKEN

openssl rand -hex 32
npx wrangler secret put SERVER_AUTH_TOKEN

# Configure and deploy
# Edit wrangler.jsonc with your account_id
npm run deploy
```

### Test

```bash
# Health check
curl https://YOUR-WORKER.workers.dev/health

# Execute task
curl -X POST https://YOUR-WORKER.workers.dev/execute \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"task": "What is 2 + 2?"}'
```

---

## Critical Gotchas

These are hard-won lessons from actual deployment. **Read carefully.**

### 1. Base Image Must Be cloudflare/sandbox

```dockerfile
# CORRECT
FROM docker.io/cloudflare/sandbox:0.7.0

# WRONG - causes Error 1101
FROM node:20-slim
```

### 2. Use getSandbox() API

```typescript
// CORRECT
import { getSandbox } from "@cloudflare/sandbox";
const sandbox = getSandbox(env.Sandbox, "unique-id");

// WRONG - older API
const sandbox = await Sandbox.create(env.SANDBOX, {...});
```

### 3. Export the Sandbox Class

```typescript
// REQUIRED in index.ts
export { Sandbox } from "@cloudflare/sandbox";
```

### 4. Use --permission-mode, NOT --dangerously-skip-permissions

```typescript
// CORRECT - works in sandbox (runs as root)
const cmd = `claude -p "${task}" --permission-mode acceptEdits`;

// WRONG - fails because sandbox runs as root
const cmd = `claude --dangerously-skip-permissions -p "${task}"`;
```

### 5. Binding Name Must Match

```jsonc
// wrangler.jsonc
"durable_objects": {
  "bindings": [{ "class_name": "Sandbox", "name": "Sandbox" }]
}
```

```typescript
// index.ts - must match "name" above
interface Env {
  Sandbox: DurableObjectNamespace;
}
```

### 6. containers:write Permission Required

```bash
npx wrangler login
# Ensure containers:write is granted
```

---

## Required Configuration

### Dockerfile

```dockerfile
FROM docker.io/cloudflare/sandbox:0.7.0
RUN npm install -g @anthropic-ai/claude-code
ENV COMMAND_TIMEOUT_MS=300000
EXPOSE 3000
```

### wrangler.jsonc

```jsonc
{
  "containers": [{
    "class_name": "Sandbox",
    "image": "./Dockerfile",
    "instance_type": "standard-1",
    "max_instances": 5
  }],
  "durable_objects": {
    "bindings": [{ "class_name": "Sandbox", "name": "Sandbox" }]
  },
  "migrations": [{ "new_sqlite_classes": ["Sandbox"], "tag": "v1" }]
}
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| 1101 | Wrong base image | Use `cloudflare/sandbox:0.7.0` |
| containers:write | Missing permission | Re-run `wrangler login` |
| root privileges | Wrong flag | Use `--permission-mode acceptEdits` |
| 401 from Anthropic | Bad OAuth token | Re-run `claude setup-token` |

---

## Resources

- **Reference Implementation:** https://github.com/WellDunDun/claude-code-sandbox
- **Cloudflare Sandbox Docs:** https://developers.cloudflare.com/sandbox/
- **Sandbox SDK GitHub:** https://github.com/cloudflare/sandbox-sdk
- **Claude Code Tutorial:** https://developers.cloudflare.com/sandbox/tutorials/claude-code/

---

## Costs

| Component | Cost |
|-----------|------|
| Workers Paid | $5/month |
| Container CPU | ~$0.072/vCPU-hour |
| Container Memory | ~$0.009/GiB-hour |
| R2 Storage | First 10GB free |

Typical usage: $15-40/month (excluding Claude MAX subscription).
