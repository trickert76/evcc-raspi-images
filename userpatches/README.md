This directory is consumed by Armbian Build during image creation. The `customize-image.sh` script runs inside the chroot to install and configure packages.

Parameters are passed via `evcc-image.env` by the outer `scripts/build-armbian.sh` wrapper.
