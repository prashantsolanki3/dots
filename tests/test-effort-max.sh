#!/usr/bin/env bash
# Unit test: ensure Claude Code is pinned to "max" effort.
#
# Validates two layers of enforcement that dots still owns:
#   1. Static: both checked-in settings.json files declare effortLevel: max.
#   2. Wiring: both install paths (Ansible role + standalone install.sh) install
#      the preserve-effort-max hook via ai-toolkit's dots-baseline preset.
#
# The preserve-effort-max.sh hook script itself, and its idempotency / drift /
# malformed-JSON / settings.json-registration behaviour, now live in ai-toolkit
# (@prashantsolanki3/ai-toolkit) and are covered by ai-toolkit's own test
# suite. dots no longer ships the script, so testing the script's runtime
# behaviour here would either require a network install (breaking the
# "no network" guarantee) or assert on a file that only exists post-install.
# Instead, Layer 2 guards the *wiring* so this test fails loud if either
# install path stops installing the hook bundle.
#
# No Docker / no network. Runs in ~1s. Run manually.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROLE_SETTINGS="$REPO_ROOT/roles/claude_code/files/settings.json"
STANDALONE_SETTINGS="$REPO_ROOT/files/claude-code/settings.json"
ROLE_TASKS="$REPO_ROOT/roles/claude_code/tasks/main.yml"
STANDALONE_INSTALL="$REPO_ROOT/files/claude-code/install.sh"

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

# ── Layer 2: ai-toolkit hook-install wiring ──────────────────────────────────
# The dots-baseline preset is what carries preserve-effort-max; assert both
# install paths invoke ai-toolkit with it. If someone drops the asset-install
# step, the effort-max hook silently stops being installed — this catches that.
echo ""
echo "── Layer 2: ai-toolkit hook-install wiring ─────────────────────────"

# The role no longer ships the hook script in-repo — guard against a regression
# that re-introduces a stale in-repo copy / dangling reference.
if [ -e "$REPO_ROOT/roles/claude_code/files/hooks" ]; then
  fail "stale roles/claude_code/files/hooks/ exists (ai-toolkit owns hooks now)"
else
  pass "no stale in-repo hooks dir (ai-toolkit owns hooks)"
fi

for path in "$ROLE_TASKS" "$STANDALONE_INSTALL"; do
  [ -f "$path" ] || { fail "missing file: $path"; continue; }
  if grep -q '@prashantsolanki3/ai-toolkit' "$path" \
     && grep -q 'dots-baseline' "$path" \
     && grep -q 'claude-code' "$path"; then
    pass "$(basename "$path"): installs dots-baseline via ai-toolkit"
  else
    fail "$(basename "$path"): missing ai-toolkit dots-baseline install wiring"
  fi
done

# install.sh must fail loud (not silently skip) if npx is unavailable.
if grep -q 'npx not found' "$STANDALONE_INSTALL"; then
  pass "install.sh fails loud when npx is missing"
else
  fail "install.sh does not guard for missing npx (could silently skip hook install)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ──────────────────────────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
[ "$FAIL" = "0" ] || exit 1
