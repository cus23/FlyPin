#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor/idevice"
COMMIT="c5b23e228249e384cf3e034fd379bf8b9abb76e2"
BASE_URL="https://raw.githubusercontent.com/StephenDev0/StikDebug/$COMMIT/StikDebug/idevice"

mkdir -p "$VENDOR_DIR"

curl --fail --location --retry 3 \
  "$BASE_URL/idevice.h" \
  --output "$VENDOR_DIR/idevice.h"
curl --fail --location --retry 3 \
  "$BASE_URL/libidevice_ffi.a" \
  --output "$VENDOR_DIR/libidevice_ffi.a"

EXPECTED_HEADER="864b8c5b15cce6280c7645b49980a626b3a44aeabfdaf30124881b9b2a47a5c4"
EXPECTED_LIBRARY="6524066d54ef23e00d46445c04dfc694e180196d54119d718f68434fa225be35"
ACTUAL_HEADER="$(shasum -a 256 "$VENDOR_DIR/idevice.h" | awk '{print $1}')"
ACTUAL_LIBRARY="$(shasum -a 256 "$VENDOR_DIR/libidevice_ffi.a" | awk '{print $1}')"

if [[ "$ACTUAL_HEADER" != "$EXPECTED_HEADER" || "$ACTUAL_LIBRARY" != "$EXPECTED_LIBRARY" ]]; then
  echo "Pinned idevice FFI files failed SHA-256 verification." >&2
  exit 1
fi

echo "Pinned idevice FFI header and static library verified."
