# Raspberry Pi Imager Integration

Provides evcc images metadata for the official Raspberry Pi Imager.

## How It Works

When a new release is published, the `update-rpi-imager.yml` workflow automatically:
- Downloads the latest release information
- Calculates checksums and file sizes  
- Updates the `rpi-imager.json` file
- Publishes it to GitHub Pages

**URL**: `https://evcc-io.github.io/images/rpi-imager.json`

**Supported Devices**:
- Raspberry Pi 3, 4, 5 (64-bit)

## Manual Update

```bash
./scripts/rpi-imager/update.sh
```

This will fetch the latest release and update `rpi-imager.json` with checksums and file sizes.

## Testing

Launch Raspberry Pi Imager with a custom repository file:

```bash
"/Applications/Raspberry Pi Imager.app/Contents/MacOS/rpi-imager" --repo "/path/to/rpi-imager.json"
```