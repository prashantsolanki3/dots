#!/usr/bin/env bash
set -e
# Container entrypoint — sets up SSH access and credential persistence.

# ── SSH: inject host public key (idempotent — no duplicates) ─────────────────
mkdir -p /root/.ssh && chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
if [ -f /tmp/host_id_rsa.pub ]; then
  host_key="$(cat /tmp/host_id_rsa.pub)"
  if ! grep -qxF "$host_key" /root/.ssh/authorized_keys; then
    printf '%s\n' "$host_key" >> /root/.ssh/authorized_keys
    echo "SSH: authorized key loaded from host"
  else
    echo "SSH: authorized key already present"
  fi
fi
ssh-keygen -A
service ssh start
echo "SSH ready — connect with: ssh root@localhost -p 2222"

# ── Claude credentials: persist across rebuilds via named volume ──────────────
# Named volume mounted at /root/.claude-credentials — survives container rebuilds.
# We symlink .credentials.json into ~/.claude/ so claude finds it automatically.
mkdir -p /root/.claude /root/.claude-credentials
if [ ! -L /root/.claude/.credentials.json ]; then
  ln -sf /root/.claude-credentials/.credentials.json /root/.claude/.credentials.json
  echo "Claude: credentials linked to persistent volume"
fi

exec sleep infinity
