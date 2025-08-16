#!/usr/bin/env bash
set -euo pipefail

# Install evcc via APT repository per docs
if [[ "$EVCC_CHANNEL" == "unstable" ]]; then
  curl -1sLf 'https://dl.evcc.io/public/evcc/unstable/setup.deb.sh' | bash -E
else
  curl -1sLf 'https://dl.evcc.io/public/evcc/stable/setup.deb.sh' | bash -E
fi

apt-get update
apt-get install -y evcc

# Pre-generate minimal config if missing
if [[ ! -f /etc/evcc.yaml ]]; then
  cat >/etc/evcc.yaml <<YAML
network:
  schema: https
  host: ${EVCC_HOSTNAME}.local
  port: 80
YAML
fi

# Enable evcc service
systemctl enable evcc || true


