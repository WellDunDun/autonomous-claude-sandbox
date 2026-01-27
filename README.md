# Cloudflare Sandbox Skill

Deploy Claude Code on Cloudflare Sandbox containers for autonomous AI task execution.

## Installation

Install this skill using the [Agent Skills CLI](https://skills.sh):

```bash
npx skills add WellDunDun/cloudflare-sandbox-skill
```

Or manually add to your agent's skills directory:

```bash
# Claude Code
git clone https://github.com/WellDunDun/cloudflare-sandbox-skill.git ~/.claude/skills/CloudflareSandbox

# Cursor
git clone https://github.com/WellDunDun/cloudflare-sandbox-skill.git ~/.cursor/skills/CloudflareSandbox

# Other agents
git clone https://github.com/WellDunDun/cloudflare-sandbox-skill.git ~/.agent/skills/CloudflareSandbox
```

## What This Skill Does

This skill guides AI agents through deploying Claude Code on Cloudflare's Sandbox container infrastructure. It enables:

- **Isolated Execution** - Run Claude Code in secure, isolated containers
- **API Access** - Execute AI coding tasks via simple HTTP endpoints
- **Auto-scaling** - Cloudflare manages container lifecycle

## Trigger Phrases

Say any of these to activate the skill:

- "Setup cloudflare sandbox"
- "Deploy claude sandbox"
- "Create sandbox worker"
- "Set up Claude Code on Cloudflare"

## Workflows

| Workflow | Description |
|----------|-------------|
| `Setup.md` | Complete setup from scratch |
| `Deploy.md` | Deploy or update existing deployment |
| `Troubleshoot.md` | Diagnose and fix common issues |

## Deterministic Tools

Scripts that output JSON for AI agent consumption:

| Tool | Purpose |
|------|---------|
| `check-prerequisites.sh` | Verify Docker, Node, wrangler auth |
| `validate-config.sh` | Check Dockerfile, wrangler.jsonc, index.ts |
| `test-deployment.sh` | Health check + test task execution |
| `diagnose.sh` | Gather all troubleshooting info |
| `generate-token.sh` | Generate secure auth token |

```bash
# Example: Check if ready to deploy
./Tools/check-prerequisites.sh | jq .success
# Returns: true or false

# Example: Test a deployment
./Tools/test-deployment.sh https://my-worker.workers.dev my-token | jq .
```

## Prerequisites

- Cloudflare account with Workers Paid plan ($5/month)
- Docker Desktop running locally
- Node.js 18+
- Claude MAX subscription

## Reference Implementation

A working implementation is available at:
https://github.com/WellDunDun/claude-code-sandbox

## Compatibility

This skill is compatible with 30+ AI coding agents including:

- Claude Code
- Cursor
- Cline
- GitHub Copilot
- Windsurf
- And more...

## License

MIT
