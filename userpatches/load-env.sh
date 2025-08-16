#!/usr/bin/env bash
# Load environment variables for evcc image customization

# Load parameters injected by outer build script
ENV_FILE="/evcc-image.env"
if [[ -f /userpatches/evcc-image.env ]]; then
  cp /userpatches/evcc-image.env "$ENV_FILE"
elif [[ -f /etc/evcc-image.env ]]; then
  cp /etc/evcc-image.env "$ENV_FILE"
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

# Set defaults
export EVCC_CHANNEL=${EVCC_CHANNEL:-stable}
export EVCC_HOSTNAME=${EVCC_HOSTNAME:-evcc}
export TIMEZONE=${TIMEZONE:-Europe/Berlin}
export DEBIAN_FRONTEND=noninteractive

echo "[load-env] hostname=$EVCC_HOSTNAME channel=$EVCC_CHANNEL tz=$TIMEZONE"
