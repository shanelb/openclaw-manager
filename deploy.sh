#!/bin/bash

# Usage:
#   ./deploy.sh              # push local skills, config, workspace → VPS (memory/ on VPS never touched)
#   ./deploy.sh --pull-first # pull from VPS first, then deploy (use when VPS is ahead or to snapshot memories locally)

# Configuration
RPC_USER="root"
RPC_HOST="187.127.153.221"
REMOTE_BASE="/docker/openclaw-zfb6/data/.openclaw"
CONTAINER_NAME="openclaw-zfb6-openclaw-1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--pull-first" ]]; then
  echo "⬇️ Pull-first: syncing VPS → local (including memory/ backup), then deploying..."
  "$SCRIPT_DIR/pull.sh"
  echo ""
fi

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
