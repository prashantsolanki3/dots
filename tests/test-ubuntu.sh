#!/usr/bin/env bash
# Run the Claude Code Ansible task + smoke-test the CLI inside a fresh Ubuntu container.
# Usage:
#   ./tests/test-ubuntu.sh                        # anthropic (default)
#   ./tests/test-ubuntu.sh --provider bedrock
#
# Prerequisites (provider-specific credentials must be exported before running):
#   anthropic    — export ANTHROPIC_API_KEY=sk-ant-...
#   openai-compat — export ANTHROPIC_API_KEY=<gateway-key> ANTHROPIC_BASE_URL=<url>
#   bedrock      — export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_REGION=...
#   vertex       — export ANTHROPIC_VERTEX_PROJECT_ID=... CLOUD_ML_REGION=...
#   foundry      — export ANTHROPIC_FOUNDRY_RESOURCE=... (Azure credentials via env)
set -e

PROVIDER="${PROVIDER:-anthropic}"
DOCKER="${DOCKER:-/usr/local/bin/docker}"
COMPOSE="$DOCKER compose -f docker-compose.test.yml"

usage() {
  echo "Usage:"
  echo "  ./tests/test-ubuntu.sh [--provider <provider>]"
  echo "  Providers: anthropic (default) | bedrock | vertex | openai-compat | foundry"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
        echo "Error: --provider requires a non-empty value." >&2
        usage >&2
        exit 1
      fi
      PROVIDER="$2"
      shift 2
      ;;
    --provider=*)
      PROVIDER="${1#--provider=}"
      if [[ -z "$PROVIDER" ]]; then
        echo "Error: --provider requires a non-empty value." >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$(dirname "$0")/.."

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
case "$PROVIDER" in
  anthropic|openai-compat)
    if [[ -z "$ANTHROPIC_API_KEY" ]]; then
      echo "SKIP: ANTHROPIC_API_KEY is not set. Export it to run the connectivity test."
    else
      $COMPOSE exec -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" ubuntu-test \
        claude -p "respond with only the word PONG"
    fi
    ;;
  bedrock)
    echo "SKIP: Bedrock connectivity test requires live AWS credentials."
    echo "  SSH in and run: source /root/.claude/active-provider.env && claude -p 'say PONG'"
    ;;
  vertex)
    echo "SKIP: Vertex connectivity test requires live GCP credentials."
    echo "  SSH in and run: source /root/.claude/active-provider.env && claude -p 'say PONG'"
    ;;
  foundry)
    echo "SKIP: Foundry connectivity test requires live Azure credentials."
    echo "  SSH in and run: source /root/.claude/active-provider.env && claude -p 'say PONG'"
    ;;
  *)
    echo "SKIP: Unknown provider '$PROVIDER' — skipping connectivity test."
    ;;
esac
