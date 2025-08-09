# evcc Armbian Image Builder

This repository builds Armbian-based images that include:

- evcc (via official APT repo)
- Cockpit (web console on 9090)
- Caddy (reverse proxy exposing evcc at 443 with internal TLS)

Defaults

- Hostname: `evcc` (reachable via mDNS as `evcc.local`)
- evcc listens on 7070 and is reverse-proxied by Caddy on 443/80
- Cockpit is enabled (port 9090)

Build locally

```bash
./scripts/build-armbian.sh \
  --board rpi4b \
  --release bookworm \
  --hostname evcc \
  --evcc-channel stable \
  --default-username admin \
  --default-password 'changeme'
```

GitHub Actions

- Manual trigger with inputs for username/password/hostname/channel.
- Produces images for Raspberry Pi 4 (`rpi4b`) and Radxa E52C (`radxa-e52c`) by default.

References

- evcc installation docs: https://docs.evcc.io/en/docs/installation/linux
