# Troubleshoot Workflow

Diagnose and fix common Cloudflare Sandbox issues.

## Diagnostic Commands

### Check Deployment Status

```bash
npx wrangler deployments list
```

### View Real-Time Logs

```bash
npx wrangler tail
```

### Check Container Status

```bash
npx wrangler containers list
```

### Test Health Endpoint

```bash
curl https://YOUR-WORKER.workers.dev/health
```

---

## Error Reference

### Error 1101

**Symptom:** Worker returns Error 1101 or container fails to start.

**Cause:** Wrong Dockerfile base image.

**Fix:**
1. Open `Dockerfile`
2. Ensure first line is:
   ```dockerfile
   FROM docker.io/cloudflare/sandbox:0.7.0
   ```
3. Redeploy: `npm run deploy`

---

### "containers:write" Scope Error

**Symptom:** Deployment fails with scope/permission error.

**Cause:** Wrangler not authenticated with container permissions.

**Fix:**
```bash
npx wrangler login
```

When browser opens, ensure `containers:write` is checked.

---

### "--dangerously-skip-permissions cannot be used with root/sudo privileges"

**Symptom:** Task execution fails with this error.

**Cause:** Sandbox runs as root, Claude Code rejects dangerous flag.

**Fix:**
1. Open `src/index.ts`
2. Change the command from:
   ```typescript
   const cmd = `claude --dangerously-skip-permissions -p "${task}"`;
   ```
   To:
   ```typescript
   const cmd = `claude -p "${task}" --permission-mode acceptEdits`;
   ```
3. Redeploy: `npm run deploy`

---

### 401 Unauthorized from Anthropic

**Symptom:** Task execution returns 401 from Anthropic API.

**Cause:** CLAUDE_CODE_OAUTH_TOKEN is invalid or expired.

**Fix:**
```bash
# Generate new token
claude setup-token

# Update secret
npx wrangler secret put CLAUDE_CODE_OAUTH_TOKEN

# Redeploy
npm run deploy
```

---

### 401 Unauthorized from Worker

**Symptom:** Request to /execute returns 401.

**Cause:** Wrong or missing SERVER_AUTH_TOKEN in request.

**Fix:**
1. Verify you're using the correct token in the Authorization header
2. If token is lost, generate and set a new one:
   ```bash
   openssl rand -hex 32
   npx wrangler secret put SERVER_AUTH_TOKEN
   ```

---

### Task Timeout

**Symptom:** Task fails with timeout error.

**Cause:** Task took longer than allowed timeout.

**Fix:**
1. Increase timeout in request:
   ```json
   {"task": "...", "timeout": 600000}
   ```
2. Or increase default in Dockerfile:
   ```dockerfile
   ENV COMMAND_TIMEOUT_MS=600000
   ```

---

### "Sandbox" Not Found / Binding Error

**Symptom:** Error about Sandbox binding not found.

**Cause:** Mismatch between wrangler.jsonc and code.

**Fix:**
1. Verify `wrangler.jsonc`:
   ```jsonc
   "durable_objects": {
     "bindings": [{ "class_name": "Sandbox", "name": "Sandbox" }]
   }
   ```
2. Verify `src/index.ts`:
   ```typescript
   interface Env {
     Sandbox: DurableObjectNamespace;
   }
   ```
3. Verify export:
   ```typescript
   export { Sandbox } from "@cloudflare/sandbox";
   ```

---

### getSandbox is Not a Function

**Symptom:** Runtime error about getSandbox.

**Cause:** Wrong import or outdated SDK.

**Fix:**
1. Check import:
   ```typescript
   import { getSandbox } from "@cloudflare/sandbox";
   ```
2. Verify package.json has:
   ```json
   "@cloudflare/sandbox": "^0.7.0"
   ```
3. Reinstall: `npm install`

---

## Still Stuck?

1. Check Cloudflare status: https://www.cloudflarestatus.com/
2. Review Cloudflare Sandbox docs: https://developers.cloudflare.com/sandbox/
3. Check GitHub issues: https://github.com/cloudflare/sandbox-sdk/issues

## Diagnostic Script

Run this to gather diagnostics:

```bash
echo "=== Wrangler Version ==="
npx wrangler --version

echo "=== Deployments ==="
npx wrangler deployments list 2>&1 | head -20

echo "=== Containers ==="
npx wrangler containers list 2>&1

echo "=== Docker Status ==="
docker info 2>&1 | head -10

echo "=== Health Check ==="
curl -s https://YOUR-WORKER.workers.dev/health | jq .
```
