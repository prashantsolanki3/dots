# Claude Code hooks

Shell scripts deployed to `~/.claude/hooks/` and invoked from the `hooks` block
in `~/.claude/settings.json`.

## `preserve-effort-max.sh`

Keeps `effortLevel: max` pinned in `~/.claude/settings.json`.

### Why

The Claude CLI rewrites `~/.claude/settings.json` whenever the user toggles
plugins, edits permissions, or accepts a security prompt. Historically these
rewrites have dropped the `effortLevel` key (per the Anthropic changelog:
*"Fixed `--effort` CLI flag being reset by unrelated settings writes on
startup"*). This hook self-heals after such rewrites.

### Behaviour

| Starting state of `~/.claude/settings.json` | Result |
|---|---|
| File missing | Created with `{"effortLevel":"max"}` |
| Key missing | Key added, other keys preserved |
| `effortLevel` set to anything other than `max` | Reset to `max` |
| `effortLevel` already `max` | No-op (mtime preserved — idempotent) |
| File contains malformed JSON | Hook exits 0 silently — never clobbers user data |

The hook never blocks session start: it always exits 0, even on failure. The
worst case is that the user sees the same broken state they already had.

### Wiring

`roles/claude_code/files/settings.json` registers the hook under
`hooks.SessionStart`. The Ansible role (`roles/claude_code/tasks/main.yml`)
deploys every `*.sh` in this directory to `~/.claude/hooks/` — symlinked
in `link` mode, copied (mode 0755) in `copy` mode (Docker).

### Manual test

```bash
./tests/test-effort-max.sh
```
