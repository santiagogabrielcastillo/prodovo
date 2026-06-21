#!/bin/bash
# Workspace-level agent initialization on the persistent volume.
# The image already has claude-code, opencode-ai, and gentle-ai baked in.
# This script handles the parts that must run once per workspace (not per image rebuild).
# Safe to re-run — all commands are idempotent.

set -e

echo "Initializing AI workspace..."

# 1. Configure gentle-ai for this project workspace.
# HOME must point to the Rails root so gentle-ai accepts paths like
# /rails/.claude/agents/* as valid (it rejects anything outside $HOME).
# pi is baked into the image at /usr/local/bin/pi — no install needed.
HOME=/rails gentle-ai install --scope=workspace

# 2. Initialize SDD project structure (.agents/ directory and skill registry).
# Guard: skip if already initialized to avoid paying re-init token cost.
if [ ! -d ".agents" ]; then
  if command -v sdd-init &> /dev/null; then
    sdd-init
  else
    echo "sdd-init not available yet, skipping. Run it manually with: bin/agent_mux"
  fi
else
  echo "SDD already initialized, skipping sdd-init."
fi

mkdir -p /rails/tmp
touch /rails/tmp/.setup_done
echo "Setup complete."
