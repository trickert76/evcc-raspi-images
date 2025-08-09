#!/usr/bin/env bash
set -euo pipefail

# build-armbian.sh
# Wrapper to run Armbian Build in Docker and produce customized images containing
# evcc, cockpit and caddy with reverse proxy to evcc on 443 (TLS internal).

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

BOARD=""
RELEASE="bookworm"
HOSTNAME="evcc"
EVCC_CHANNEL="stable" # stable|unstable
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="admin"

usage() {
  cat <<EOF
Usage: $0 --board <armbian-board> [--release <debian>] [--hostname <name>] \
          [--evcc-channel stable|unstable] [--default-username <name>] \
          [--default-password <pwd>]

Examples:
  $0 --board rpi4b --release bookworm --hostname evcc --default-username admin --default-password 'changeme'
  $0 --board radxa-e52c

Supported boards are those supported by Armbian mainline (e.g. rpi4b, radxa-e52c if available).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --board) BOARD="$2"; shift 2 ;;
    --release) RELEASE="$2"; shift 2 ;;
    --hostname) HOSTNAME="$2"; shift 2 ;;
    --evcc-channel) EVCC_CHANNEL="$2"; shift 2 ;;
    --default-username) DEFAULT_USERNAME="$2"; shift 2 ;;
    --default-password) DEFAULT_PASSWORD="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$BOARD" ]]; then
  echo "--board is required" >&2
  usage
  exit 2
fi

mkdir -p "$REPO_ROOT/dist" "$REPO_ROOT/logs"

# Prepare a temporary userpatches with variables passed to customize-image.sh
BUILDTMP=$(mktemp -d)
trap 'rm -rf "$BUILDTMP"' EXIT
mkdir -p "$BUILDTMP/userpatches/overlay/etc"

# Exported to the chroot via /etc/armbian-image.env
cat >"$BUILDTMP/userpatches/overlay/etc/evcc-image.env" <<ENV
EVCC_CHANNEL=${EVCC_CHANNEL}
EVCC_HOSTNAME=${HOSTNAME}
DEFAULT_USERNAME=${DEFAULT_USERNAME}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD}
ENV

# Copy our customize script and auxiliary files
cp -a "$REPO_ROOT/userpatches/." "$BUILDTMP/userpatches/"
chmod +x "$BUILDTMP/userpatches/customize-image.sh" || true

IMAGE_OUT_DIR="$REPO_ROOT/dist/${BOARD}"
mkdir -p "$IMAGE_OUT_DIR"

# Clone Armbian build framework and run it in Docker mode (it will build its own container image).
BUILD_DIR="$BUILDTMP/build"
git clone --depth=1 https://github.com/armbian/build.git "$BUILD_DIR"

# Place our userpatches into the build tree
rm -rf "$BUILD_DIR/userpatches"
cp -a "$BUILDTMP/userpatches" "$BUILD_DIR/userpatches"

echo "Starting build for board=${BOARD} release=${RELEASE} using Armbian build"
pushd "$BUILD_DIR" >/dev/null
  EXPERT=yes \
  SKIP_LOG_ARCHIVE=yes \
  SET_OWNER_TO_UID=$(id -u) \
  ./compile.sh \
    BOARD="$BOARD" \
    BRANCH=current \
    RELEASE="$RELEASE" \
    BUILD_MINIMAL=no \
    BUILD_DESKTOP=no \
    KERNEL_CONFIGURE=no \
    COMPRESS_OUTPUTIMAGE=sha,zip
popd >/dev/null

# Copy results
if compgen -G "$BUILD_DIR/output/images/*" > /dev/null; then
  cp -a "$BUILD_DIR/output/images/"* "$IMAGE_OUT_DIR/"
fi

echo "Build done. Output in $IMAGE_OUT_DIR"


