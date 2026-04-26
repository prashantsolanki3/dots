# Tokens & Auth Reference

Every credential the dots-managed Claude Code setup may consume. Set the ones you actually need — most plugins work without any token.

## Required (one of)

| Variable | Used by | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | Claude Code CLI | Skip if you authenticate via OAuth (`claude login`). |

## Plugin auth

| Variable | Plugin | Required? | Notes |
|---|---|---|---|
| `GH_TOKEN` / `GITHUB_TOKEN` | `github` | yes (if used) | Personal access token. `repo` scope for private repos. The `gh` CLI also picks this up. |
| `TFE_TOKEN` | `terraform` | optional | HCP Terraform / TFE API token — only needed for private registries and `create_run` / workspace mutations. Public registry browsing works without it. |
| `TELEGRAM_BOT_TOKEN` | `telegram` | yes (if used) | Bot token from [@BotFather](https://t.me/botfather). Read by the official `telegram` MCP server. |
| `TELEGRAM_TOKEN` | `claudeclaw` | yes (if used) | Same value as `TELEGRAM_BOT_TOKEN` — claudeclaw uses a different env var name (upstream PR [#128](https://github.com/moazbuilds/claudeclaw/pull/128)). Set both if you use both. |
| `DISCORD_TOKEN` | `claudeclaw` | optional | Bot token from [discord.com/developers/applications](https://discord.com/developers/applications). Required only if you enable claudeclaw's Discord channel. |

## MCP-server auth (defined in `roles/claude_code/files/mcp/`)

| Variable | MCP server | Notes |
|---|---|---|
| `SONARQUBE_TOKEN` | `sonarqube` | User token from SonarCloud (`https://sonarcloud.io/account/security`) or self-hosted SonarQube. |
| `SONARQUBE_ORGANIZATION` | `sonarqube` | Org slug, e.g. `my-org`. Only needed for SonarCloud. For self-hosted, override `SONARQUBE_URL` in `roles/claude_code/files/mcp/sonarqube.json` (the resulting `mcpServers` entry lands in `~/.claude.json`). |

`qmd` MCP needs no auth — it indexes local markdown only.

## No auth needed

These plugins work out of the box:
`ralph-loop`, `code-review`, `pr-review-toolkit`, `session-report`, `security-guidance`, `claude-md-management`, `hookify`, `code-simplifier`, `playwright`, `caveman`.

## Where to put tokens

### macOS / Linux host (`link` mode)

Add to your shell rc (`~/.zshrc`, `~/.bashrc`) or a per-project `.envrc` (direnv):

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export GH_TOKEN="ghp_..."
export SONARQUBE_TOKEN="..."
export SONARQUBE_ORGANIZATION="my-org"
export TELEGRAM_BOT_TOKEN="..."
export TELEGRAM_TOKEN="$TELEGRAM_BOT_TOKEN"   # claudeclaw reads this name
export DISCORD_TOKEN="..."
```

The `claude plugin install` and MCP `${VAR}` substitution both read from the live shell environment.

### Docker container (`copy` mode)

Pass these variables through in your Compose file or container environment
(replace `your-service` with whatever you've named the service):

```yaml
services:
  your-service:
    environment:
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
      GH_TOKEN:          ${GH_TOKEN:-}
      TFE_TOKEN:         ${TFE_TOKEN:-}
      TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:-}
      TELEGRAM_TOKEN:    ${TELEGRAM_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}
      DISCORD_TOKEN:     ${DISCORD_TOKEN:-}
      SONARQUBE_TOKEN:   ${SONARQUBE_TOKEN:-}
      SONARQUBE_ORGANIZATION: ${SONARQUBE_ORGANIZATION:-}
```

…or use `env_file: .env` and source from a host `.env`. Dots itself ships
`docker-compose.test.yml` for the Ansible test harness; downstream projects
provide their own compose file (see `prashantsolanki3/yolo` for an example).

## Verification

After provisioning:

```bash
# Plugins installed
claude plugin list

# MCP servers registered
jq '.mcpServers | keys' ~/.claude.json

# Quick functional checks
claude --print '/sonar quality_gates'    # sonarqube MCP
claude --print 'list my recent repos'    # github plugin
```

If a plugin or MCP fails silently, run `claude --debug ...` and check `~/.claude/debug/` for the JSON-RPC handshake log.

## Adding a new credential

1. Pick an env var name and document it here.
2. If it's for a new MCP, drop a JSON file in `roles/claude_code/files/mcp/<name>.json` with `${VAR}` placeholders — see `files/mcp/README.md`.
3. Re-run `ansible-playbook dev.yml` (or restart the dev container).

Never commit real tokens. Keep `.env`, `~/.claude/active-provider.env`, and `~/.config/claudeclaw/env` out of any repo — if you keep a project `.env`, make sure it's in `.gitignore`.
