#!/usr/bin/env bash
# Claude Code CLI setup — symlinks ~/.claude/ to this repo's config.
# Supports macOS (Apple Silicon and Intel) and Linux / WSL2.
# No hardcoded paths: SCRIPT_DIR is resolved at runtime.
#
# Usage:
#   ./install.sh                        # defaults to --provider anthropic
#   ./install.sh --provider bedrock
#   ./install.sh --provider vertex
#   ./install.sh --provider openai-compat
#   ./install.sh --provider foundry
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROVIDER="anthropic"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      if [ -z "${2:-}" ]; then echo "Error: --provider requires a value"; echo "Usage: $0 [--provider anthropic|bedrock|vertex|openai-compat|foundry]"; exit 1; fi; PROVIDER="$2"
      shift 2
      ;;
    --provider=*)
      PROVIDER="${1#--provider=}"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--provider anthropic|bedrock|vertex|openai-compat|foundry]" >&2
      exit 1
      ;;
  esac
done

PROVIDER_ENV="$SCRIPT_DIR/models/${PROVIDER}.env"
if [[ ! -f "$PROVIDER_ENV" ]]; then
  echo "Error: no provider profile found at $PROVIDER_ENV" >&2
  echo "Available profiles:" >&2
  for f in "$SCRIPT_DIR/models/"*.env; do
    echo "  $(basename "${f%.env}")" >&2
  done
  exit 1
fi

# ── Platform detection ────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Darwin*)
    PLATFORM="macOS"
    if [ "$ARCH" = "arm64" ]; then
      BREW_PREFIX="/opt/homebrew"   # Apple Silicon
    else
      BREW_PREFIX="/usr/local"      # Intel Mac
    fi
    ;;
  Linux*)
    PLATFORM="Linux"
    BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"  # Linuxbrew / WSL2
    ;;
  *)
    PLATFORM="$OS"
    BREW_PREFIX="/usr/local"
    ;;
esac

echo "Platform : $PLATFORM ($ARCH)"
echo "Provider : $PROVIDER"
echo "Source   : $SCRIPT_DIR"
echo "Target   : $CLAUDE_DIR"
echo ""

# ── Create target directory ───────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ── Symlink core config files ─────────────────────────────────────────────────
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "  linked  settings.json       → $SCRIPT_DIR/settings.json"

ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  linked  CLAUDE.md           → $SCRIPT_DIR/CLAUDE.md"

# ── Symlink active provider profile ──────────────────────────────────────────
ln -sf "$PROVIDER_ENV" "$CLAUDE_DIR/active-provider.env"
echo "  linked  active-provider.env → $PROVIDER_ENV"

# ── Generic assets (agents/commands/skills/hooks/mcp) via ai-toolkit ──────────
# ai-toolkit (@prashantsolanki3/ai-toolkit) is the single source of truth for
# the generic Claude Code asset bundle — this mirrors what
# roles/claude_code/tasks/main.yml does in the Ansible flow. It installs the
# `dots-baseline` preset into ~/.claude AND registers hooks (e.g.
# preserve-effort-max) in settings.json keyed off each hook's `event:`
# frontmatter — something the old in-repo symlink could not do. Requires npx
# (bundled with Node). Fail loud if npx is missing rather than silently
# skipping, so the effort-max hook can never quietly go uninstalled.
AI_TOOLKIT_VERSION="1.0.0"
if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx not found on PATH — required to install Claude Code assets" >&2
  echo "       via @prashantsolanki3/ai-toolkit. Install Node.js and re-run." >&2
  exit 1
fi
echo "  installing agents/commands/skills/hooks/mcp via ai-toolkit (dots-baseline)…"
npx --yes "@prashantsolanki3/ai-toolkit@${AI_TOOLKIT_VERSION}" install \
  --tool claude-code --scope global --preset dots-baseline \
  --target "$CLAUDE_DIR" --link

# ── Shell activation instructions ────────────────────────────────────────────
SHELL_NAME="$(basename "${SHELL:-}")"
case "$SHELL_NAME" in
  zsh)  RC_FILE="~/.zshrc";  RELOAD_HINT="source ~/.zshrc" ;;
  bash) RC_FILE="~/.bashrc"; RELOAD_HINT="source ~/.bashrc" ;;
  *)    RC_FILE="your shell rc file"; RELOAD_HINT="restart your shell or source the relevant rc file" ;;
esac

echo ""
echo "Done. Add this line to $RC_FILE so the provider"
echo "profile is sourced whenever you open a terminal:"
echo ""
echo '  [ -f ~/.claude/active-provider.env ] && source ~/.claude/active-provider.env'
echo ""
echo "Then reload:  $RELOAD_HINT"
echo ""
echo "Verify:"
echo "  ls -la $CLAUDE_DIR/settings.json $CLAUDE_DIR/CLAUDE.md $CLAUDE_DIR/active-provider.env"
echo "  claude --version"
