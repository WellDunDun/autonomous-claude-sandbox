# Monitor Workflow

Ongoing monitoring and operations for Cloudflare Sandbox deployments.

## Real-Time Logs

```bash
# Stream logs from worker
npx wrangler tail

# Filter for errors only
npx wrangler tail --format=json | jq 'select(.level == "error")'
```

## Container Status

```bash
# List active containers
npx wrangler containers list

# Check container health
npx wrangler containers list --format=json | jq '.[] | {id, status, created}'
```

## Deployment Status

```bash
# View recent deployments
npx wrangler deployments list

# Check current deployment
npx wrangler deployments list --format=json | jq '.[0]'
```

## Health Monitoring

### Automated Health Check

```bash
# Quick health check
curl -s https://YOUR-WORKER.workers.dev/health | jq .

# Full test suite
./Tools/test-deployment.sh https://YOUR-WORKER.workers.dev YOUR_TOKEN | jq .
```

### Cron-Based Monitoring

Set up a cron job for regular checks:

```bash
# Add to crontab
*/5 * * * * /path/to/Tools/test-deployment.sh https://worker.dev token >> /var/log/sandbox-health.log 2>&1
```

## Key Metrics to Watch

| Metric | Where to Find | Alert Threshold |
|--------|---------------|-----------------|
| Response time | Cloudflare dashboard | > 30s |
| Error rate | `wrangler tail` | > 5% |
| Container starts | `containers list` | Unusual spikes |
| Auth failures | Logs | Any increase |

## Common Issues to Monitor

### Container Cold Starts

Containers may take 2-3 seconds to start. Monitor for:
- First request latency spikes
- Container creation frequency

### Token Expiration

OAuth tokens expire. Watch for:
- 401 errors from Anthropic
- Sudden task failures

```bash
# Check for auth errors in logs
npx wrangler tail --format=json | jq 'select(.message | contains("401"))'
```

### Resource Limits

Monitor container resource usage:
- CPU time limits
- Memory usage
- Execution timeouts

## Alerting Setup

### Using Cloudflare Notifications

1. Go to Cloudflare Dashboard > Notifications
2. Create alert for Worker errors
3. Set threshold and notification channel

### Custom Alerting Script

```bash
#!/bin/bash
RESULT=$(./Tools/test-deployment.sh https://worker.dev token)
SUCCESS=$(echo $RESULT | jq -r '.success')

if [ "$SUCCESS" != "true" ]; then
  echo "ALERT: Sandbox deployment failing" | mail -s "Sandbox Alert" you@example.com
fi
```

## Log Analysis

### Find Slow Requests

```bash
npx wrangler tail --format=json | jq 'select(.duration > 10000)'
```

### Find Failed Tasks

```bash
npx wrangler tail --format=json | jq 'select(.outcome == "exception")'
```

## Periodic Maintenance

### Weekly
- Review error logs
- Check container utilization
- Verify OAuth token validity

### Monthly
- Review costs in Cloudflare dashboard
- Check for SDK updates
- Audit R2 storage usage

### Quarterly
- Security review
- Performance optimization
- Capacity planning
