#!/usr/bin/env bash
# Unit test: ensure Claude Code is pinned to "max" effort.
#
# Validates two layers of enforcement:
#   1. Static: both checked-in settings.json files declare effortLevel: max.
#   2. Runtime: the preserve-effort-max.sh hook is idempotent and self-healing.
#
# No Docker / no network. Runs in ~1s (includes a `sleep 1` to cross the
# filesystem mtime boundary for the idempotency check). Run manually.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROLE_SETTINGS="$REPO_ROOT/roles/claude_code/files/settings.json"
STANDALONE_SETTINGS="$REPO_ROOT/files/claude-code/settings.json"
HOOK="$REPO_ROOT/roles/claude_code/files/hooks/preserve-effort-max.sh"

PASS=0
FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

# ── Layer 1: static settings ─────────────────────────────────────────────────
echo "── Layer 1: static settings ─────────────────────────────────────────"
for f in "$ROLE_SETTINGS" "$STANDALONE_SETTINGS"; do
  [ -f "$f" ] || { fail "missing file: $f"; continue; }
  level=$(python3 -c "import json; print(json.load(open('$f')).get('effortLevel', ''))")
  if [ "$level" = "max" ]; then
    pass "$f → effortLevel=max"
  else
    fail "$f → effortLevel='$level' (want 'max')"
  fi
done

# ── Layer 2: hook script ─────────────────────────────────────────────────────
echo ""
echo "── Layer 2: preserve-effort-max.sh hook ────────────────────────────"
[ -x "$HOOK" ] || fail "hook not executable: $HOOK"
[ -x "$HOOK" ] && pass "hook is executable"

# Sandbox: scratch HOME with throw-away settings file
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/.claude"
SANDBOX_SETTINGS="$SANDBOX/.claude/settings.json"

# Case A: missing key → hook adds it
echo '{"env":{"X":"1"}}' > "$SANDBOX_SETTINGS"
HOME="$SANDBOX" "$HOOK" >/dev/null 2>&1 || true
got=$(python3 -c "import json; print(json.load(open('$SANDBOX_SETTINGS')).get('effortLevel'))")
[ "$got" = "max" ] && pass "case A: adds effortLevel when missing" \
  || fail "case A: got '$got', expected 'max'"

# Case A.1: hook preserves untouched keys
got_x=$(python3 -c "import json; print(json.load(open('$SANDBOX_SETTINGS')).get('env',{}).get('X'))")
[ "$got_x" = "1" ] && pass "case A.1: preserves unrelated keys" \
  || fail "case A.1: env.X='$got_x', expected '1'"

# Case B: drifted value → hook resets to max
echo '{"effortLevel":"low","env":{"X":"1"}}' > "$SANDBOX_SETTINGS"
HOME="$SANDBOX" "$HOOK" >/dev/null 2>&1 || true
got=$(python3 -c "import json; print(json.load(open('$SANDBOX_SETTINGS')).get('effortLevel'))")
[ "$got" = "max" ] && pass "case B: resets drifted value to max" \
  || fail "case B: got '$got', expected 'max'"

# Case C: already max → hook is a no-op (idempotent, no rewrite)
echo '{"effortLevel":"max","env":{"X":"1"}}' > "$SANDBOX_SETTINGS"
mtime_before=$(stat -c %Y "$SANDBOX_SETTINGS" 2>/dev/null || stat -f %m "$SANDBOX_SETTINGS")
sleep 1
HOME="$SANDBOX" "$HOOK" >/dev/null 2>&1 || true
mtime_after=$(stat -c %Y "$SANDBOX_SETTINGS" 2>/dev/null || stat -f %m "$SANDBOX_SETTINGS")
[ "$mtime_before" = "$mtime_after" ] && pass "case C: idempotent (no rewrite when already max)" \
  || fail "case C: file rewritten unnecessarily (mtime $mtime_before → $mtime_after)"

# Case D: missing settings.json → hook creates it
rm -f "$SANDBOX_SETTINGS"
HOME="$SANDBOX" "$HOOK" >/dev/null 2>&1 || true
[ -f "$SANDBOX_SETTINGS" ] && \
  got=$(python3 -c "import json; print(json.load(open('$SANDBOX_SETTINGS')).get('effortLevel'))") || got=""
[ "$got" = "max" ] && pass "case D: creates settings.json when missing" \
  || fail "case D: file not created or effortLevel='$got'"

# Case E: malformed JSON → hook should NOT clobber (silent no-op + non-fatal)
echo 'not json {' > "$SANDBOX_SETTINGS"
HOME="$SANDBOX" "$HOOK" >/dev/null 2>&1
rc=$?
content=$(cat "$SANDBOX_SETTINGS")
[ "$rc" = "0" ] && [ "$content" = "not json {" ] && pass "case E: leaves malformed JSON untouched, exits 0" \
  || fail "case E: rc=$rc content='$content'"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ──────────────────────────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
[ "$FAIL" = "0" ] || exit 1
