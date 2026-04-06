#!/usr/bin/env bash
# Run the Claude Code Ansible task + smoke-test the CLI inside a fresh Ubuntu container.
# Usage:
#   ./tests/test-ubuntu.sh                        # anthropic (default)
#   ./tests/test-ubuntu.sh --provider bedrock
#
# Prerequisites:
#   export ANTHROPIC_API_KEY=sk-ant-...   (or equivalent for your provider)
set -e

PROVIDER="${PROVIDER:-anthropic}"
DOCKER="${DOCKER:-/usr/local/bin/docker}"
COMPOSE="$DOCKER compose -f docker-compose.test.yml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --provider=*) PROVIDER="${1#--provider=}"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

cd "$(dirname "$0")/.."

# Warn early if API key is missing
if [[ -z "$ANTHROPIC_API_KEY" ]]; then
  echo "WARNING: ANTHROPIC_API_KEY is not set — connectivity test will fail."
  echo "  Export it first: export ANTHROPIC_API_KEY=sk-ant-..."
  echo ""
fi

echo "==> Building image"
$COMPOSE build ubuntu-test

echo "==> Starting container"
$COMPOSE up -d ubuntu-test

cleanup() {
  echo "==> Stopping container"
  $COMPOSE down
}
trap cleanup EXIT

echo ""
echo "── Step 1: Ansible run (provider: $PROVIDER) ─────────────────────────────"
$COMPOSE exec ubuntu-test \
  ansible-playbook mac.yml \
    -e "dotfiles_dir=/dots" \
    -e "claude_provider=$PROVIDER"

echo ""
echo "── Step 2: Verify symlinks ───────────────────────────────────────────────"
$COMPOSE exec ubuntu-test bash -c "
  ls -la /root/.claude/settings.json /root/.claude/CLAUDE.md /root/.claude/active-provider.env
"

echo ""
echo "── Step 3: claude --version ──────────────────────────────────────────────"
$COMPOSE exec ubuntu-test claude --version

echo ""
echo "── Step 4: API connectivity test ─────────────────────────────────────────"
$COMPOSE exec -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" ubuntu-test \
  claude -p "respond with only the word PONG"
