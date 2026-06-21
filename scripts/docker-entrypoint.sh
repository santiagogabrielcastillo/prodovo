#!/bin/bash
set -e

cd /rails

echo "[entrypoint] Running workspace setup..."
scripts/setup_dev_env.sh

exec "$@"
