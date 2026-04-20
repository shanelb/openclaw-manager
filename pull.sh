#!/bin/bash
# Pull OpenClaw skills + config from the VPS into this repo (overwrites local files).

RPC_USER="root"
RPC_HOST="187.127.153.221"
REMOTE_BASE="/docker/openclaw-zfb6/data/.openclaw"

set -e
echo "⬇️ Pulling from ${RPC_USER}@${RPC_HOST}:${REMOTE_BASE} ..."

rsync -avz "${RPC_USER}@${RPC_HOST}:${REMOTE_BASE}/skills/" ./.openclaw/skills/
rsync -avz "${RPC_USER}@${RPC_HOST}:${REMOTE_BASE}/openclaw.json" ./.openclaw/openclaw.json

echo "✅ Local .openclaw/ updated. openclaw.json is gitignored; commit skill changes as needed."
