# evcc Images for Raspberry Pi and other SBCs

[![Built with Depot](https://depot.dev/badges/built-with-depot.svg)](https://depot.dev/?utm_source=evcc)

Repository for ready-to-use Debian-based [evcc](https://evcc.io) images for popular single-board computers like Raspberry Pi, Radxa and NanoPi.

## Image contents

- ☀️🚗 [evcc](https://evcc.io) for smart energy management
- 🔒 [Caddy](https://caddyserver.com) reverse proxy for HTTPS
- 🛠️ [Cockpit](https://cockpit-project.org) web console for administration
- 🐧 [Armbian](https://www.armbian.com) base image and build system

## How to use

- Download your image file from [releases](https://github.com/evcc-io/images/releases).
- Flash your image to an SD card using [balenaEtcher](https://www.balena.io/etcher/) or [USBImager](https://gitlab.com/bztsrc/usbimager).
- Insert your SD card and connect your device with power and ethernet.
- Navigate to `https://evcc.local/` in your browser. Accept the self-signed certificate.
- You should see the evcc web interface.

## Security

- Login into the [Cockpit](https://cockpit-project.org) web console on `https://evcc.local:9090/`
  - username `admin`
  - password `admin`
- **Change your password(!!)** to something more secure.
- Alternatively: connect via SSH `ssh admin@evcc.local`

## Supported Boards

| Name                                                                                      | Armbian Code | Instructions                                                                              |
| ----------------------------------------------------------------------------------------- | ------------ | ----------------------------------------------------------------------------------------- |
| [Raspberry Pi](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)              | `rpi4b`      |                                                                                           |
| [Radxa E52C](https://radxa.com/products/network-computer/e52c/)                           | `radxa-e52c` | [flash to eMMC](https://docs.radxa.com/en/e/e52c/getting-started/install-os/maskrom)      |
| [NanoPi R3S](https://www.friendlyelec.com/index.php?route=product/product&product_id=311) | `nanopi-r3s` | [copy from SD to eMMC](https://docs.armbian.com/User-Guide_Getting-Started/#installation) |

## Storage recommendations

Running from built-in eMMC is recommended. Radxa E52C and NanoPi R3S come with built-in storage.

If you decide to run your system directly from SD card, be sure to read [Armbian's recommendations](https://docs.armbian.com/User-Guide_Getting-Started/#armbian-getting-started-guide) first.

## Contributing

- [Report issues](https://github.com/evcc-io/images/issues)
- [Submit pull requests](https://github.com/evcc-io/images/pulls)

## License

- [MIT](LICENSE)
