#!/usr/bin/env bash
set -euo pipefail

# This script runs inside the Armbian chroot during image creation.
# It orchestrates the installation and configuration of evcc, cockpit, and caddy
# through numbered setup scripts for better maintainability.

echo "[customize-image] starting"

# Load environment variables
source /userpatches/load-env.sh

# Execute setup scripts in order
for script in /userpatches/setup-scripts/[0-9][0-9]-*.sh; do
    if [[ -f "$script" ]]; then
        echo "[customize-image] executing $(basename "$script")"
        bash "$script"
    fi
done

echo "[customize-image] done"
