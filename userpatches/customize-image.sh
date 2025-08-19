#!/usr/bin/env bash
set -euo pipefail

# This script runs inside the Armbian chroot during image creation.
# It installs and configures evcc, cockpit, and caddy in a single consolidated script.

echo "[customize-image] starting"

# Load environment variables
echo "[customize-image] loading environment variables"

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

echo "[customize-image] hostname=$EVCC_HOSTNAME channel=$EVCC_CHANNEL tz=$TIMEZONE"

# ============================================================================
# SYSTEM SETUP
# ============================================================================
echo "[customize-image] setting up system"

# Update system packages
apt-get update
apt-get -y full-upgrade

# Install base networking utils and mdns (avahi)
apt-get install -y --no-install-recommends \
  curl ca-certificates gnupg apt-transport-https \
  avahi-daemon avahi-utils libnss-mdns \
  sudo network-manager python3-gi python3-dbus

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

# Lock the root account to prevent any login
passwd -l root

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

# Ensure admin home directory has correct ownership
chown admin:admin /home/admin

# Enable mDNS service
systemctl enable avahi-daemon || true

# Ensure root home exists for Cockpit terminal (normally present)
test -d /root || mkdir -p /root
chown -R root:root /root

# ============================================================================
# COMITUP WIFI SETUP
# ============================================================================
echo "[customize-image] setting up comitup for wifi configuration"

# Install latest comitup from official repository (fixes device type compatibility)
curl -L -o /tmp/davesteele-comitup-apt-source.deb \
  "https://davesteele.github.io/comitup/deb/davesteele-comitup-apt-source_1.3_all.deb"
dpkg -i /tmp/davesteele-comitup-apt-source.deb || apt-get install -f -y
apt-get update
apt-get install -y --no-install-recommends comitup
rm -f /tmp/davesteele-comitup-apt-source.deb

# Clean up any potential interface conflicts
rm -f /etc/network/interfaces || true

# Mask conflicting services as recommended
# Note: Don't mask dnsmasq as comitup needs it for DHCP in AP mode
# Don't mask dnsmasq - comitup needs it for DHCP in AP mode
# Configure systemd-resolved to not conflict with dnsmasq
systemctl mask dhcpcd.service || true
systemctl mask wpa-supplicant.service || true

# Configure systemd-resolved to not use port 53
mkdir -p /etc/systemd/resolved.conf.d
cat >/etc/systemd/resolved.conf.d/comitup.conf <<'RESOLVEDCONF'
[Resolve]
# Don't bind to port 53 - let dnsmasq use it for AP mode
DNSStubListener=no
RESOLVEDCONF

# Ensure dnsmasq is available but not auto-starting (comitup will manage it)
systemctl disable dnsmasq.service || true
systemctl stop dnsmasq.service || true

# Create minimal dnsmasq configuration for comitup DHCP
mkdir -p /etc/dnsmasq.d
cat >/etc/dnsmasq.d/comitup.conf <<'DNSMASQCONF'
bind-interfaces
dhcp-range=10.42.0.10,10.42.0.50,255.255.255.0,12h
dhcp-option=3,10.42.0.1
dhcp-option=6,10.42.0.1
port=0
no-resolv
no-poll
DNSMASQCONF

# Ensure NetworkManager is enabled (already installed earlier)
systemctl enable NetworkManager.service || true

# Ensure hostapd is available for AP mode
systemctl disable hostapd.service || true
systemctl stop hostapd.service || true

# Configure comitup with minimal evcc-specific settings
cat >/etc/comitup.conf <<'COMITUPCONF'
ap_name: evcc-setup
ap_timeout: 3600
external_callback: /usr/local/bin/comitup-callback.sh
ap_ip: 10.42.0.1
ap_ip_start: 10.42.0.10
ap_ip_end: 10.42.0.50
enable_appliance_mode: true
COMITUPCONF

# Create callback script to manage evcc service during wifi setup
cat >/usr/local/bin/comitup-callback.sh <<'CALLBACK'
#!/bin/bash
# comitup callback script - temporarily manages evcc during WiFi setup

STATE="$1"
SSID="$2"

case "$STATE" in
    HOTSPOT)
        # Stop evcc service when entering hotspot mode to free port 80
        systemctl stop evcc || true
        echo "$(date): Entered HOTSPOT mode - stopped evcc service"
        ;;
    CONNECTING)
        echo "$(date): Connecting to WiFi: $SSID"
        ;;
    CONNECTED)
        # Stop comitup services to free port 80
        systemctl stop comitup-web.service || true
        systemctl disable comitup.service || true
        systemctl disable comitup-web.service || true
        
        # Start evcc service when connected to wifi
        systemctl start evcc || true
        echo "$(date): Connected to WiFi: $SSID - started evcc service"
        
        # Mark that we've seen internet connection (prevent future AP mode)
        touch /var/lib/comitup/internet-seen
        ;;
    FAIL)
        echo "$(date): Failed to connect to WiFi: $SSID"
        ;;
esac
CALLBACK

chmod +x /usr/local/bin/comitup-callback.sh

# Create systemd service to check internet connectivity and manage comitup startup
cat >/etc/systemd/system/evcc-comitup-manager.service <<'MANAGER'
[Unit]
Description=evcc WiFi Setup Manager (enables comitup only when needed)
After=NetworkManager.service
Before=comitup.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/evcc-comitup-manager.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
MANAGER

# Create the manager script
cat >/usr/local/bin/evcc-comitup-manager.sh <<'MANAGERSH'
#!/bin/bash
# evcc WiFi manager - enables comitup AP mode only when no network connectivity

INTERNET_SEEN_FILE="/var/lib/comitup/internet-seen"
LOG_FILE="/var/log/evcc-comitup.log"

log() {
    echo "$(date): $*" | tee -a "$LOG_FILE"
}

# Create comitup state directory
mkdir -p /var/lib/comitup

# Give network interfaces time to initialize (avoid 2min systemd wait)
sleep 10

# Check if we've seen internet before
if [[ -f "$INTERNET_SEEN_FILE" ]]; then
    log "Internet connection seen before - disabling comitup AP mode"
    systemctl disable comitup.service || true
    systemctl stop comitup.service || true
    systemctl enable evcc.service || true
    exit 0
fi

# Check for ethernet connection
ETH_CONNECTED=false
for iface in $(ls /sys/class/net/ | grep -E '^(eth|en)'); do
    if [[ -f "/sys/class/net/$iface/carrier" ]] && [[ "$(cat /sys/class/net/$iface/carrier 2>/dev/null)" == "1" ]]; then
        ETH_CONNECTED=true
        log "Ethernet connection detected on $iface"
        break
    fi
done

# Check for WiFi configuration
WIFI_CONFIGURED=false
if nmcli -t -f TYPE,AUTOCONNECT connection show | grep -q "802-11-wireless:yes"; then
    WIFI_CONFIGURED=true
    log "WiFi configuration found"
fi

# Decide whether to start comitup (evcc runs by default, comitup only when needed)
if [[ "$ETH_CONNECTED" == "true" ]]; then
    log "Ethernet connected - evcc will run normally, comitup not needed"
    systemctl disable comitup.service || true
    systemctl stop comitup.service || true
elif [[ "$WIFI_CONFIGURED" == "true" ]]; then
    # WiFi is configured, try to connect
    log "WiFi configured - attempting connection"
    # Give NetworkManager some time to connect
    sleep 10
    
    # Check if we got internet
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log "WiFi connected with internet - evcc will run normally, comitup not needed"
        touch "$INTERNET_SEEN_FILE"
        systemctl disable comitup.service || true
        systemctl stop comitup.service || true
    else
        log "WiFi configured but no connection - enabling comitup AP mode"
        systemctl enable comitup.service || true
        # Note: comitup callback will handle stopping/starting evcc as needed
    fi
else
    log "No ethernet, no WiFi configured - enabling comitup AP mode"
    systemctl enable comitup.service || true
    # Note: comitup callback will handle stopping/starting evcc as needed
fi
MANAGERSH

chmod +x /usr/local/bin/evcc-comitup-manager.sh

# Enable the manager service
systemctl enable evcc-comitup-manager.service || true

# Create NetworkManager configuration for comitup compatibility
cat >/etc/NetworkManager/conf.d/comitup.conf <<'NMCONF'
[main]
unmanaged-devices=interface-name:comitup-*,type:wifi-p2p

[device]
wifi.scan-rand-mac-address=no

[connectivity]
uri=http://detectportal.firefox.com/canonical.html
interval=300
NMCONF

# evcc is the primary service - it will be enabled by default in the evcc setup section

# ============================================================================
# EVCC SETUP
# ============================================================================
echo "[customize-image] setting up evcc"

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
YAML
fi

# Enable evcc service
systemctl enable evcc || true

# ============================================================================
# COCKPIT SETUP
# ============================================================================
echo "[customize-image] setting up cockpit"

# Install Cockpit and related packages
apt-get install -y --no-install-recommends \
  cockpit cockpit-pcp \
  packagekit cockpit-packagekit \
  cockpit-networkmanager

# Cockpit configuration
mkdir -p /etc/cockpit
cat >/etc/cockpit/cockpit.conf <<'COCKPITCONF'
[WebService]
LoginTo = false
LoginTitle = "evcc"
COCKPITCONF

# Enable services
systemctl enable cockpit.socket || true
systemctl enable packagekit || true

# ============================================================================
# CADDY SETUP
# ============================================================================
echo "[customize-image] setting up caddy"

# Install Caddy
apt-get install -y --no-install-recommends caddy

# Caddy configuration with internal TLS and reverse proxy to evcc:80
mkdir -p /etc/caddy
cat >/etc/caddy/Caddyfile <<CADDY
{
  email admin@example.com
  auto_https disable_redirects
}

# HTTPS on 443 with Caddy internal TLS
${EVCC_HOSTNAME}.local:443 {
  tls internal
  encode zstd gzip
  log
  reverse_proxy 127.0.0.1:80
}

CADDY

# Enable Caddy service
systemctl enable caddy || true

# ============================================================================
# CLEANUP
# ============================================================================
echo "[customize-image] cleaning up"

# Mask noisy console setup units on headless images
systemctl mask console-setup.service || true
systemctl mask keyboard-setup.service || true

# Clean apt caches to keep image small and silence Armbian warnings about non-empty apt dirs
apt-get -y autoremove --purge || true
apt-get clean || true
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /var/cache/apt/* || true

echo "[customize-image] done"