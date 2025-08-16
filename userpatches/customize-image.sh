#!/usr/bin/env bash
set -euo pipefail

# This script runs inside the Armbian chroot during image creation.
# It orchestrates the installation and configuration of evcc, cockpit, and caddy
# through numbered setup scripts for better maintainability.

echo "[customize-image] starting"

# Load environment variables
echo "[customize-image] sourcing environment from /tmp/load-env.sh"
source /tmp/load-env.sh

# Execute setup scripts in order
echo "[customize-image] executing setup scripts from /tmp/setup-scripts"
for script in /tmp/setup-scripts/[0-9][0-9]-*.sh; do
    if [[ -f "$script" ]]; then
        echo "[customize-image] executing $(basename "$script")"
        bash "$script"
    fi
done

echo "[customize-image] done"
