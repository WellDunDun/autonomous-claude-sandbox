# Setup Workflow

Complete setup guide for deploying Claude Code on Cloudflare Sandboxes.

## Prerequisites Check

Before starting, verify:

- [ ] Cloudflare account with Workers Paid plan ($5/month)
- [ ] Docker Desktop is running
- [ ] Node.js 18+ installed
- [ ] Claude MAX subscription active

## Step 1: Clone Reference Project

```bash
git clone https://github.com/WellDunDun/claude-code-sandbox.git
cd claude-code-sandbox
npm install
```

Or create from scratch using the templates below.

## Step 2: Authenticate with Cloudflare

```bash
npx wrangler login
```

**CRITICAL:** When prompted, ensure you grant the `containers:write` scope. Without this, deployment will fail.

## Step 3: Create R2 Bucket

```bash
npx wrangler r2 bucket create claude-results
```

This stores task execution results.

## Step 4: Set Secrets

### Get Claude OAuth Token

```bash
# Run where you're logged into Claude Code locally
claude setup-token
```

Copy the token, then:

```bash
npx wrangler secret put CLAUDE_CODE_OAUTH_TOKEN
# Paste your setup-token when prompted
```

### Generate Server Auth Token

```bash
# Generate a secure random token
openssl rand -hex 32
```

Copy the output, then:

```bash
npx wrangler secret put SERVER_AUTH_TOKEN
# Paste the generated token when prompted
```

**IMPORTANT:** Save your `SERVER_AUTH_TOKEN` - you need it for API requests.

## Step 5: Configure wrangler.jsonc

Copy the example and edit:

```bash
cp wrangler.jsonc.example wrangler.jsonc
```

Update these values:
- `account_id` - Your Cloudflare account ID (find in dashboard URL)
- `name` - Your desired worker name

### Required Configuration

```jsonc
{
  "name": "your-worker-name",
  "account_id": "YOUR_CLOUDFLARE_ACCOUNT_ID",
  "main": "src/index.ts",
  "compatibility_date": "2025-01-27",
  "compatibility_flags": ["nodejs_compat"],
  "observability": {
    "logs": {
      "enabled": true,
      "invocation_logs": true
    }
  },
  "containers": [
    {
      "class_name": "Sandbox",
      "image": "./Dockerfile",
      "instance_type": "standard-1",
      "max_instances": 5
    }
  ],
  "durable_objects": {
    "bindings": [
      {
        "class_name": "Sandbox",
        "name": "Sandbox"
      }
    ]
  },
  "migrations": [
    {
      "new_sqlite_classes": ["Sandbox"],
      "tag": "v1"
    }
  ],
  "r2_buckets": [
    {
      "binding": "RESULTS",
      "bucket_name": "claude-results"
    }
  ]
}
```

## Step 6: Verify Dockerfile

Ensure your Dockerfile uses the correct base image:

```dockerfile
FROM docker.io/cloudflare/sandbox:0.7.0
RUN npm install -g @anthropic-ai/claude-code
ENV COMMAND_TIMEOUT_MS=300000
EXPOSE 3000
```

**CRITICAL:** Must use `cloudflare/sandbox:0.7.0` - any other image will fail with Error 1101.

## Step 7: Deploy

```bash
npm run deploy
```

First deployment takes 2-3 minutes (builds Docker image). Subsequent deploys are faster.

## Step 8: Test Deployment

### Health Check

```bash
curl https://YOUR-WORKER.workers.dev/health
```

Expected response:
```json
{
  "status": "healthy",
  "platform": "cloudflare_sandboxes",
  "auth_method": "claude_subscription_setup_token"
}
```

### Execute a Task

```bash
curl -X POST https://YOUR-WORKER.workers.dev/execute \
  -H "Authorization: Bearer YOUR_SERVER_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"task": "What is 2 + 2? Just respond with the number."}'
```

Expected response:
```json
{
  "taskId": "uuid",
  "success": true,
  "stdout": "4",
  "stderr": "",
  "output": "4"
}
```

## Troubleshooting

### Error 1101

**Cause:** Wrong Dockerfile base image.

**Fix:** Use `FROM docker.io/cloudflare/sandbox:0.7.0`

### containers:write scope error

**Fix:** Re-run `npx wrangler login` and grant all permissions.

### "--dangerously-skip-permissions cannot be used with root"

**Cause:** Sandbox runs as root.

**Fix:** Use `--permission-mode acceptEdits` instead.

### 401 from Anthropic

**Cause:** Invalid or expired OAuth token.

**Fix:**
```bash
claude setup-token
npx wrangler secret put CLAUDE_CODE_OAUTH_TOKEN
npm run deploy
```

## Monitoring

```bash
# Real-time logs
npx wrangler tail

# Container status
npx wrangler containers list

# View deployments
npx wrangler deployments list
```

## Costs

| Component | Cost |
|-----------|------|
| Workers Paid | $5/month |
| Container CPU | ~$0.072/vCPU-hour |
| Container Memory | ~$0.009/GiB-hour |
| R2 Storage | First 10GB free |

Typical usage: $15-40/month (excluding Claude MAX subscription).
