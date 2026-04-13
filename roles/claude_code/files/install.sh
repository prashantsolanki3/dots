#!/usr/bin/env bash
# Claude Code CLI setup — symlinks ~/.claude/ to this repo's config.
# Supports macOS (Apple Silicon and Intel) and Linux / WSL2.
# No hardcoded paths: SCRIPT_DIR is resolved at runtime.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

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
echo "Source   : $SCRIPT_DIR"
echo "Target   : $CLAUDE_DIR"
echo ""

# ── Create target directory ───────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/agents"

# ── Symlink core config files ─────────────────────────────────────────────────
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "  linked  settings.json → $SCRIPT_DIR/settings.json"

ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  linked  CLAUDE.md     → $SCRIPT_DIR/CLAUDE.md"

# ── Symlink individual agent files (safe: never replaces the whole agents dir) ─
AGENT_COUNT=0
for f in "$SCRIPT_DIR/agents/"*.md; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
  echo "  linked  agents/$(basename "$f") → $f"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
[ "$AGENT_COUNT" -eq 0 ] && echo "  (no agent files to install)"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Done. Verify:"
echo "  ls -la $CLAUDE_DIR/settings.json $CLAUDE_DIR/CLAUDE.md"
echo "  claude --version"
