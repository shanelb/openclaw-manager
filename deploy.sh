#!/bin/bash

# Push local → VPS and restart. Does not upload workspace/memory/ (remote memories stay safe).
#
# Workflow (do not chain pull+deploy blindly):
#   1. ./pull.sh   — only when you want VPS → local (backup memory/, reconcile with server).
#   2. Edit locally, commit if you like.
#   3. ./deploy.sh — push your edits.
# Pulling right before deploy just round-trips the same files and overwrites any uncommitted
# local changes, so run pull and deploy as separate intentional steps.

# Configuration
RPC_USER="root"
RPC_HOST="187.127.153.221"
REMOTE_BASE="/docker/openclaw-zfb6/data/.openclaw"
CONTAINER_NAME="openclaw-zfb6-openclaw-1"

echo "🚀 Deploying updates from Cursor..."

# 1. Sync Skills
rsync -avz --delete ./.openclaw/skills/ $RPC_USER@$RPC_HOST:$REMOTE_BASE/skills/

# 2. Sync Config
rsync -avz ./.openclaw/openclaw.json $RPC_USER@$RPC_HOST:$REMOTE_BASE/openclaw.json

# 3. Sync agent workspace (SOUL, IDENTITY, AGENTS, USER, TOOLS, …)
#    --exclude memory/: never overwrite remote daily memory logs from this machine.
#    Pull memories with ./pull.sh when you want them locally.
rsync -avz --exclude='memory/' ./workspace/ $RPC_USER@$RPC_HOST:$REMOTE_BASE/workspace/

echo "♻️ Restarting Openclaw Container..."
if ssh $RPC_USER@$RPC_HOST "docker restart $CONTAINER_NAME"; then
    echo "✅ Success! Container restarted and project is live."
else
    echo "❌ ERROR: Failed to restart container. Check the container name."
    exit 1
fi
