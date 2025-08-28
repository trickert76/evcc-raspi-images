# Raspberry Pi Imager Integration

Provides evcc images metadata for the official Raspberry Pi Imager.

## How It Works

When a new release is published, the `update-rpi-imager.yml` workflow automatically:
- Downloads the latest release information
- Calculates checksums and file sizes  
- Updates the `rpi-imager.json` file
- Publishes it to GitHub Pages

**URL**: `https://evcc-io.github.io/evcc-images/rpi-imager.json`

**Supported Devices**:
- Raspberry Pi 3, 4, 5 (64-bit)

## Manual Update

```bash
./scripts/rpi-imager/update.sh
```

This will fetch the latest release and update `rpi-imager.json` with checksums and file sizes.

## Testing

Test in Raspberry Pi Imager:
1. Open Raspberry Pi Imager
2. Press Ctrl+Shift+X for advanced options  
3. Add the JSON URL as a custom repository