# Autonomous Claude Sandbox Skill

Deploy Claude Code on Cloudflare Sandbox containers for autonomous AI task execution.

## Installation

Install this skill using the [Agent Skills CLI](https://skills.sh):

```bash
npx skills add WellDunDun/autonomous-claude-sandbox
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

## Architecture

See [architecture.md](./architecture.md) for detailed technical diagrams showing the request flow from client through Worker, Durable Object, and Sandbox Container.

## What This Skill Does

This skill enables AI agents to deploy AND execute tasks on Cloudflare's Sandbox container infrastructure:

- **Setup & Deploy** - Guide agents through deploying Claude Code on Cloudflare
- **Task Execution** - Send tasks to the sandbox for isolated execution
- **Isolated Containers** - Each task runs in a secure, ephemeral environment
- **Auto-scaling** - Cloudflare manages container lifecycle

## Trigger Phrases

**Setup & Deployment:**
- "Setup autonomous claude sandbox"
- "Deploy claude on cloudflare"
- "Set up Claude Code on Cloudflare"

**Task Execution:**
- "Execute task in sandbox"
- "Run this in the sandbox"
- "Delegate to sandbox"
- "Send to autonomous claude"

## Workflows

| Workflow | Description |
|----------|-------------|
| `Execute.md` | Send tasks to sandbox for execution |
| `Setup.md` | Complete setup from scratch |
| `Deploy.md` | Deploy or update existing deployment |
| `Troubleshoot.md` | Diagnose and fix common issues |
| `Upgrade.md` | Upgrade SDK or dependencies |
| `Monitor.md` | Monitor deployment health |

## Deterministic Tools

Scripts that output JSON for AI agent consumption:

| Tool | Purpose |
|------|---------|
| `execute-task.sh` | Execute a task in the sandbox |
| `check-prerequisites.sh` | Verify Docker, Node, wrangler auth |
| `validate-config.sh` | Check Dockerfile, wrangler.jsonc, index.ts |
| `test-deployment.sh` | Health check + test task execution |
| `diagnose.sh` | Gather all troubleshooting info |
| `generate-token.sh` | Generate secure auth token |

```bash
# Execute a task in the sandbox
./Tools/execute-task.sh https://my-worker.workers.dev my-token "Write a hello world script" | jq .

# Check if ready to deploy
./Tools/check-prerequisites.sh | jq .success

# Test a deployment
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
