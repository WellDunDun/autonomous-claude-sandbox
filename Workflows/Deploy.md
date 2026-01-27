# Deploy Workflow

Deploy or update an existing Cloudflare Sandbox deployment.

## Quick Deploy

If already set up, just run:

```bash
npm run deploy
```

## Pre-Deploy Checklist

- [ ] Docker Desktop is running
- [ ] You're in the project directory
- [ ] wrangler.jsonc has correct account_id
- [ ] Secrets are set (CLAUDE_CODE_OAUTH_TOKEN, SERVER_AUTH_TOKEN)

## Deploy Command

```bash
npm run deploy
```

Or directly:

```bash
npx wrangler deploy
```

## Deployment Times

| Scenario | Time |
|----------|------|
| First deploy (builds Docker) | 2-3 minutes |
| Code changes only | 30-60 seconds |
| Dockerfile changes | 2-3 minutes |

## Verify Deployment

After deploy completes:

```bash
# Health check
curl https://YOUR-WORKER.workers.dev/health

# Test execution
curl -X POST https://YOUR-WORKER.workers.dev/execute \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"task": "What is 2 + 2?"}'
```

## View Deployment Status

```bash
# List deployments
npx wrangler deployments list

# View logs
npx wrangler tail

# Check containers
npx wrangler containers list
```

## Rollback

If something goes wrong:

```bash
# List recent deployments
npx wrangler deployments list

# Rollback to previous
npx wrangler rollback
```

## Common Issues

### "containers:write" scope error

Re-authenticate:
```bash
npx wrangler login
```

### Deployment stuck

Check Docker Desktop is running and has resources available.

### Changes not reflecting

Clear Cloudflare cache or wait a few seconds for propagation.
