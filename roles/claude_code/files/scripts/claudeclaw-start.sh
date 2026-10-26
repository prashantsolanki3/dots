#!/usr/bin/env bash
# claudeclaw-start — launch the ClaudeClaw daemon with a sanitized env so the
# bundled `claude` CLI authenticates via the platform-native credential store
# instead of inheriting a soon-to-expire OAuth access token from the parent
# Claude Code / Claude Desktop session.
#
# Why this wrapper exists
# -----------------------
# claudeclaw <= 1.0.0 only strips CLAUDECODE from the env it passes to spawned
# `claude` subprocesses (src/runner.ts cleanEnv). It leaks
# CLAUDE_CODE_OAUTH_TOKEN and CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST through.
# When you run /claudeclaw:start from inside Claude Code/Desktop, the daemon's
# children get a frozen OAuth access token (no refresh token to renew it) and
# `MANAGED_BY_HOST=1` (which disables the CLI's own credential-store fallback),
# so after ~8h every spawned claude returns HTTP 401 silently — heartbeat and
# Telegram replies both fail with no user-visible error.
#
# This wrapper strips those vars before launching the daemon. After the
# upstream fix (https://github.com/moazbuilds/claudeclaw) lands, the wrapper
# becomes a harmless no-op (the daemon will strip them itself).
#
# Cross-platform
# --------------
# Pure POSIX shell + `env -u VAR`. Works on macOS (BSD env), Linux (GNU env),
# and WSL2. The `claude` CLI handles per-platform credential storage:
#   - macOS:        Keychain ("Claude Code-credentials")
#   - Linux/WSL2:   ~/.claude/.credentials.json
#   - Windows:      Credential Manager
#
# Usage
# -----
#   claudeclaw-start                 # launch in current dir
#   claudeclaw-start /path/to/proj   # launch in given project dir
#   claudeclaw-start --foreground    # run in foreground (no nohup, no &)
#
# Prints the launched PID on stdout.
set -e

FOREGROUND=0
PROJECT_DIR=""
for arg in "$@"; do
  case "$arg" in
    --foreground|-f) FOREGROUND=1 ;;
    -*)              echo "claudeclaw-start: unknown option: $arg" >&2; exit 2 ;;
    *)               [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$arg" ;;
  esac
done
PROJECT_DIR="${PROJECT_DIR:-$PWD}"

cd "$PROJECT_DIR"
mkdir -p .claude/claudeclaw/logs

# ── User-level config (shared across every project) ────────────────────────
# ~/.config/claudeclaw/env       sourced for $VAR substitution in settings
# ~/.config/claudeclaw/settings.template.json    copied into new projects
# Both are deployed by the dots `claude_code` role; optional for users
# who install claudeclaw outside of dots.
USER_CLAUDECLAW_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claudeclaw"
USER_ENV_FILE="$USER_CLAUDECLAW_DIR/env"
USER_SETTINGS_TEMPLATE="$USER_CLAUDECLAW_DIR/settings.template.json"
PROJECT_SETTINGS=".claude/claudeclaw/settings.json"

# Source user-level env file if present so exported secrets become env vars
# in the daemon process. ClaudeClaw reads TELEGRAM_TOKEN and DISCORD_TOKEN
# directly from its environment and uses them in place of the corresponding
# fields in settings.json — see upstream
# https://github.com/moazbuilds/claudeclaw/pull/128 (merged 2026-04-26).
# Other vars (ANTHROPIC_API_KEY, GLM_API_KEY) are forwarded by cleanSpawnEnv
# in runner.ts to spawned `claude` CLI processes.
if [ -r "$USER_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$USER_ENV_FILE"
  set +a
fi

# Seed project settings from the user-level template on first launch.
# Never overwrite an existing per-project settings.json — that belongs to
# the project (and may have secrets the user edited in directly).
if [ ! -f "$PROJECT_SETTINGS" ] && [ -r "$USER_SETTINGS_TEMPLATE" ]; then
  cp "$USER_SETTINGS_TEMPLATE" "$PROJECT_SETTINGS"
  echo "claudeclaw-start: seeded $PROJECT_SETTINGS from $USER_SETTINGS_TEMPLATE" >&2
fi

# Resolve the latest installed claudeclaw version. The plugin cache layout is
# ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/. Sort by mtime so
# we pick the most recently installed.
CLAUDECLAW_DIR=$(ls -dt "$HOME/.claude/plugins/cache/claudeclaw/claudeclaw/"[0-9]*/ 2>/dev/null | head -1)
CLAUDECLAW_DIR="${CLAUDECLAW_DIR%/}"
if [ -z "$CLAUDECLAW_DIR" ] || [ ! -f "$CLAUDECLAW_DIR/src/index.ts" ]; then
  echo "claudeclaw: plugin not installed at ~/.claude/plugins/cache/claudeclaw/claudeclaw/" >&2
  echo "  install via: claude plugin marketplace add moazbuilds/claudeclaw && claude plugin install claudeclaw@claudeclaw" >&2
  exit 1
fi

# Resolve bun. PATH may not include ~/.bun/bin when invoked from a Claude Code
# slash command (the slash-command env can be slimmer than the user shell).
BUN_BIN=$(command -v bun 2>/dev/null || true)
if [ -z "$BUN_BIN" ] && [ -x "$HOME/.bun/bin/bun" ]; then
  BUN_BIN="$HOME/.bun/bin/bun"
fi
if [ -z "$BUN_BIN" ] || [ ! -x "$BUN_BIN" ]; then
  echo "claudeclaw: bun not found on PATH or at \$HOME/.bun/bin/bun" >&2
  echo "  install via: curl -fsSL https://bun.sh/install | bash" >&2
  exit 1
fi

# The strip set: env vars the parent Claude Code/Desktop session injects that
# break detached daemon auth. Anything not in this list is forwarded.
STRIP="
  CLAUDE_CODE_OAUTH_TOKEN
  CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST
  CLAUDECODE
  CLAUDE_CODE_ENTRYPOINT
  CLAUDE_CODE_EXECPATH
  CLAUDE_CODE_SDK_HAS_OAUTH_REFRESH
  CLAUDE_AGENT_SDK_VERSION
"
ENV_UNSET_ARGS=""
for v in $STRIP; do ENV_UNSET_ARGS="$ENV_UNSET_ARGS -u $v"; done

if [ "$FOREGROUND" = "1" ]; then
  # shellcheck disable=SC2086
  exec env $ENV_UNSET_ARGS "$BUN_BIN" run "$CLAUDECLAW_DIR/src/index.ts" start --web
fi

# shellcheck disable=SC2086
nohup env $ENV_UNSET_ARGS "$BUN_BIN" run "$CLAUDECLAW_DIR/src/index.ts" start --web \
  > .claude/claudeclaw/logs/daemon.log 2>&1 &
echo $!
