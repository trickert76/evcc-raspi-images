#!/usr/bin/env bash
set -euo pipefail

# Install Cockpit and related packages
apt-get install -y --no-install-recommends \
  cockpit cockpit-pcp \
  packagekit cockpit-packagekit \
  cockpit-networkmanager network-manager

# Cockpit configuration
mkdir -p /etc/cockpit
cat >/etc/cockpit/cockpit.conf <<'COCKPITCONF'
[WebService]
LoginTo = false
LoginTitle = "evcc Image Administration"
COCKPITCONF

# Enable services
systemctl enable cockpit.socket || true
systemctl enable packagekit || true


