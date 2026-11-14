#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor/idevice"
COMMIT="7a80dfce28eeb501faca6498d1746949ac921e74"
BASE_URL="https://raw.githubusercontent.com/StikDebug/StikDebug/$COMMIT/StikDebug/idevice"

mkdir -p "$VENDOR_DIR"
curl --fail --location --retry 3 "$BASE_URL/idevice.h" --output "$VENDOR_DIR/idevice.h"
curl --fail --location --retry 3 "$BASE_URL/libidevice_ffi.a" --output "$VENDOR_DIR/libidevice_ffi.a"

# These are Git blob object IDs from the immutable commit's tree.
EXPECTED_HEADER="2aef885909b7162cb92107e224390d766a4fd9bd"
EXPECTED_LIBRARY="3fb7e2dbfdb9db3d47bd6364a435bbc10d5581f9"
ACTUAL_HEADER="$(git hash-object "$VENDOR_DIR/idevice.h")"
ACTUAL_LIBRARY="$(git hash-object "$VENDOR_DIR/libidevice_ffi.a")"

if [[ "$ACTUAL_HEADER" != "$EXPECTED_HEADER" || "$ACTUAL_LIBRARY" != "$EXPECTED_LIBRARY" ]]; then
  echo "Pinned idevice FFI files failed Git object verification." >&2
  exit 1
fi

echo "Pinned idevice FFI with Cryptex DDI support verified."
