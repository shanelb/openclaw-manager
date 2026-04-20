#!/bin/bash

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

# 3. Sync agent workspace (SOUL.md, IDENTITY.md, AGENTS.md, USER.md, …)
#    No --delete: remote may have extra files (e.g. memory/) not in this repo.
rsync -avz ./workspace/ $RPC_USER@$RPC_HOST:$REMOTE_BASE/workspace/

echo "♻️ Restarting Openclaw Container..."
if ssh $RPC_USER@$RPC_HOST "docker restart $CONTAINER_NAME"; then
    echo "✅ Success! Container restarted and project is live."
else
    echo "❌ ERROR: Failed to restart container. Check the container name."
    exit 1
fi