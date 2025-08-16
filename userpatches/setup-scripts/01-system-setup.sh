#!/usr/bin/env bash
set -euo pipefail

# Update system packages
apt-get update
apt-get -y full-upgrade

# Install base networking utils and mdns (avahi)
apt-get install -y --no-install-recommends \
  curl ca-certificates gnupg apt-transport-https \
  avahi-daemon avahi-utils libnss-mdns \
  sudo

# Set timezone
apt-get install -y --no-install-recommends tzdata
echo "$TIMEZONE" >/etc/timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1 || true

# Set hostname and mdns
echo "$EVCC_HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1\s\+.*/127.0.1.1\t$EVCC_HOSTNAME/" /etc/hosts || true

# SSH hardening (Armbian/Debian Bookworm): use drop-in to override defaults
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/99-evcc.conf <<'SSHD'
# Disable SSH login for root
PermitRootLogin no
SSHD

# Disable Armbian interactive first login wizard
systemctl disable armbian-firstlogin.service || true
rm -f /root/.not_logged_in_yet || true

# Create admin user with initial password and require password change on first login
if ! id -u admin >/dev/null 2>&1; then
  useradd -m -s /bin/bash admin
fi
echo 'admin:admin' | chpasswd
chage -d 0 admin || true
usermod -aG sudo admin || true
usermod -s /bin/bash admin || true

# Ensure admin home directory exists and has correct ownership/permissions
ADMIN_HOME=$(getent passwd admin | cut -d: -f6 || true)
if [[ -z "${ADMIN_HOME:-}" ]]; then
  ADMIN_HOME="/home/admin"
fi
mkdir -p "$ADMIN_HOME"
chown -R admin:admin "$ADMIN_HOME"
chmod 700 "$ADMIN_HOME"

# Enable mDNS service
systemctl enable avahi-daemon || true

# Ensure root home exists for Cockpit terminal (normally present)
test -d /root || mkdir -p /root
chown -R root:root /root


