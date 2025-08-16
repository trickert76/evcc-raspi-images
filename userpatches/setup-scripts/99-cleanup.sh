#!/usr/bin/env bash
set -euo pipefail

# Mask noisy console setup units on headless images
systemctl mask console-setup.service || true
systemctl mask keyboard-setup.service || true

# Clean apt caches to keep image small and silence Armbian warnings about non-empty apt dirs
apt-get -y autoremove --purge || true
apt-get clean || true
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /var/cache/apt/* || true


