#!/usr/bin/env bash
set -euo pipefail

# This script runs inside the Armbian chroot during image creation.
# It orchestrates the installation and configuration of evcc, cockpit, and caddy
# through numbered setup scripts for better maintainability.

echo "[customize-image] starting"

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

# Load environment variables
echo "[customize-image] sourcing environment from $SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/load-env.sh"

# Execute setup scripts in order
echo "[customize-image] executing setup scripts from $SCRIPT_DIR/setup-scripts"
for script in "$SCRIPT_DIR"/setup-scripts/[0-9][0-9]-*.sh; do
    if [[ -f "$script" ]]; then
        echo "[customize-image] executing $(basename "$script")"
        bash "$script"
    fi
done

echo "[customize-image] done"
