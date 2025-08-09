## evcc Armbian Image Builder

This repository builds Armbian-based images that include:

- evcc (via official APT repo)
- Cockpit (web console on 9090)
- Caddy (reverse proxy exposing evcc at 443)

### Defaults

- Hostname: `evcc` (reachable via mDNS as `evcc.local`)
- evcc listens on port 80 (proxied by Caddy at 443)
- Cockpit is enabled (port 9090)
- Login: `root` / `1234` (password change forced at first login for Cockpit/SSH)

### Supported Boards

| Board          | Code         |
| -------------- | ------------ |
| Raspberry Pi 4 | `rpi4b`      |
| Raspberry Pi 5 | `rpi5b`      |
| Radxa E52C     | `radxa-e52c` |
| NanoPi R3S     | `nanopi-r3s` |

### References

- evcc installation docs: https://docs.evcc.io/en/docs/installation/linux
