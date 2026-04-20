#!/bin/bash
# Container entrypoint. Managed by dots/roles/claude_code — do not edit
# in-container; changes will be overwritten on next `ansible-playbook dev.yml`.
#
# Runs on every container start. Re-executes the idempotent claude_code role
# against the mounted ~/.claude volume so dots updates propagate without
# rebuilding the image.

# ── Docker socket access (host gid varies — dev-only convenience) ────────
if [ -S /var/run/docker.sock ]; then
  sudo chmod a+rw /var/run/docker.sock 2>/dev/null || true
fi

# ── Sync Claude state via dots Ansible ───────────────────────────────────
if [ -d /opt/dots ]; then
  ansible-playbook /opt/dots/sync-claude.yml \
    --connection=local -i "localhost," \
    -e "ansible_python_interpreter=/usr/bin/python3" \
    -e "host_username=$(whoami)" \
    -e "claude_config_mode=copy" 2>&1 | \
    grep -vE '^(PLAY|TASK|ok:|skipping:|  to retry|$)' || true
fi

# ── Git safe.directory for mounted workspace repos ───────────────────────
for repo in /workspace/*/; do
  repo="${repo%/}"
  [ -d "$repo/.git" ] && git config --global --add safe.directory "$repo" 2>/dev/null
done
git config --global user.name "${GIT_USER_NAME:-Smart Agents Dev}"
git config --global user.email "${GIT_EMAIL:-dev@smartagents.local}"

# ── Hub-specific: pre-commit hooks for backend + infra ───────────────────
for repo in smart-agents-backend qualia-ai-infrastructure; do
  if [ -d "/workspace/$repo/.git" ] && [ ! -f "/workspace/$repo/.git/hooks/pre-commit" ]; then
    (cd "/workspace/$repo" && pre-commit install 2>/dev/null) || true
  fi
done

# ── Hub-specific: website pnpm install on first boot ─────────────────────
if [ -f "/workspace/smart-agents-website/package.json" ] && \
   [ ! -d "/workspace/smart-agents-website/node_modules" ]; then
  echo "Installing website dependencies..."
  (cd /workspace/smart-agents-website && pnpm install --frozen-lockfile 2>/dev/null || pnpm install) || true
fi

# ── Auth check ───────────────────────────────────────────────────────────
AUTH=$(claude auth status 2>&1 || true)
if echo "$AUTH" | grep -q '"loggedIn": true'; then
  echo "Claude: authenticated via OAuth"
elif [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "Claude: using API key"
else
  echo "  Not authenticated. Run: claude login"
fi

exec "$@"
