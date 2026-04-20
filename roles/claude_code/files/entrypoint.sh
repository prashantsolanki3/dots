#!/usr/bin/env bash
# Container entrypoint. Managed by dots/roles/claude_code — do not edit
# in-container; changes will be overwritten on next `ansible-playbook dev.yml`.
#
# Runs on every container start. Re-executes the idempotent claude_code role
# against the mounted ~/.claude volume so dots updates propagate without
# rebuilding the image.

# ── Docker socket access (host gid varies — dev-only convenience) ────────
# World-writable socket grants any container process control over the host
# Docker daemon. Opt-in: set CLAUDE_CODE_ALLOW_WORLD_WRITABLE_DOCKER_SOCK=1.
if [ -S /var/run/docker.sock ] && [ "${CLAUDE_CODE_ALLOW_WORLD_WRITABLE_DOCKER_SOCK:-0}" = "1" ]; then
  sudo chmod a+rw /var/run/docker.sock 2>/dev/null || true
fi

# ── Re-run dots Ansible against the live container ──────────────────────
# The idempotent roles bring ~/.claude and the container's tool state back
# in sync with whatever dots has shipped (config changes, new plugins).
if [ -d /opt/dots ]; then
  set -o pipefail
  ansible-playbook /opt/dots/dev.yml \
    --connection=local -i "localhost," \
    -e "ansible_python_interpreter=/usr/bin/python3" \
    -e "host_username=$(whoami)" \
    -e "docker_install_engine=false" \
    -e "ssh_enabled=false" \
    -e "update_system=false" \
    -e "claude_config_mode=copy" 2>&1 | \
    grep -vE '^(PLAY|TASK|ok:|skipping:|  to retry|$)'
  sync_status=${PIPESTATUS[0]}
  set +o pipefail
  if [ "$sync_status" -ne 0 ]; then
    echo "entrypoint: dots sync failed (exit $sync_status); continuing with shell" >&2
  fi
fi

# ── Git safe.directory for mounted workspace repos ───────────────────────
# Check before adding to avoid growing ~/.gitconfig on every container start.
for repo in /workspace/*/; do
  repo="${repo%/}"
  if [ -d "$repo/.git" ]; then
    if ! git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "$repo"; then
      git config --global --add safe.directory "$repo" 2>/dev/null
    fi
  fi
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
