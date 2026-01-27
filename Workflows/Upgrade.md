# Upgrade Workflow

Upgrade Cloudflare Sandbox SDK and handle migrations.

## When to Upgrade

- New SDK version released
- Security patches available
- New features needed
- Cloudflare announces breaking changes

## Pre-Upgrade Checklist

```bash
# Capture current state
./Tools/diagnose.sh . > pre-upgrade-state.json

# Verify current deployment works
./Tools/test-deployment.sh https://YOUR-WORKER.workers.dev YOUR_TOKEN | jq .
```

## Step 1: Check Current Versions

```bash
# Check installed SDK version
cat package.json | jq '.dependencies["@cloudflare/sandbox"]'

# Check latest available
npm view @cloudflare/sandbox version
```

## Step 2: Review Changelog

Before upgrading, review breaking changes:
- https://github.com/cloudflare/sandbox-sdk/releases

## Step 3: Update Dependencies

```bash
# Update SDK
npm update @cloudflare/sandbox

# Or install specific version
npm install @cloudflare/sandbox@0.8.0
```

## Step 4: Update Dockerfile Base Image

If the base image version changed:

```dockerfile
# Update FROM line
FROM docker.io/cloudflare/sandbox:NEW_VERSION
```

## Step 5: Handle Migrations

If migrations are needed, update wrangler.jsonc:

```jsonc
"migrations": [
  { "new_sqlite_classes": ["Sandbox"], "tag": "v1" },
  { "tag": "v2" }  // Add new migration tag
]
```

## Step 6: Validate Configuration

```bash
./Tools/validate-config.sh . | jq .
```

## Step 7: Deploy and Test

```bash
# Deploy
npm run deploy

# Test
./Tools/test-deployment.sh https://YOUR-WORKER.workers.dev YOUR_TOKEN | jq .
```

## Step 8: Verify Post-Upgrade

```bash
# Compare with pre-upgrade state
./Tools/diagnose.sh . > post-upgrade-state.json
diff pre-upgrade-state.json post-upgrade-state.json
```

## Rollback

If issues occur:

```bash
# Rollback deployment
npx wrangler rollback

# Revert package.json
git checkout package.json package-lock.json
npm install
```

## Version Compatibility Matrix

| SDK Version | Base Image | Breaking Changes |
|-------------|------------|------------------|
| 0.7.x | cloudflare/sandbox:0.7.0 | Initial stable |
| 0.8.x | cloudflare/sandbox:0.8.0 | TBD |
