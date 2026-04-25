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
| `TELEGRAM_BOT_TOKEN` | `telegram`, `claudeclaw` | yes (if used) | Bot token from [@BotFather](https://t.me/botfather). Same token shared between the `telegram` plugin and `claudeclaw`'s telegram channel. |
| `DISCORD_BOT_TOKEN` | `claudeclaw` | optional | Only required if you enable the Discord channel in claudeclaw. |

## MCP-server auth (defined in `roles/claude_code/files/mcp/`)

| Variable | MCP server | Notes |
|---|---|---|
| `SONARQUBE_TOKEN` | `sonarqube` | User token from SonarCloud (`https://sonarcloud.io/account/security`) or self-hosted SonarQube. |
| `SONARQUBE_ORGANIZATION` | `sonarqube` | Org slug, e.g. `my-org`. Only needed for SonarCloud. Override `SONARQUBE_URL` in `mcp/sonarqube.json` for self-hosted. |

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
```

The `claude plugin install` and MCP `${VAR}` substitution both read from the live shell environment.

### Docker container (`copy` mode)

Pass through `docker-compose.yml`:

```yaml
services:
  claude-dev:
    environment:
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
      GH_TOKEN:          ${GH_TOKEN:-}
      TFE_TOKEN:         ${TFE_TOKEN:-}
      TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:-}
      DISCORD_BOT_TOKEN: ${DISCORD_BOT_TOKEN:-}
      SONARQUBE_TOKEN:   ${SONARQUBE_TOKEN:-}
      SONARQUBE_ORGANIZATION: ${SONARQUBE_ORGANIZATION:-}
```

…or use `env_file: .env` and source from a host `.env` (gitignored).

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

Never commit real tokens. `.env`, `~/.claude/active-provider.env`, and `~/.config/claudeclaw/env` are gitignored — keep it that way.
