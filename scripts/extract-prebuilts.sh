#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Put the stock kernel, dtbo and the stage 1 vendor image where
# device/hisense/hlte730t/BoardConfig.mk expects them:
#   $ANDROID_ROOT/vendor/hisense/hlte730t/prebuilt/{Image.gz-dtb,dtbo.img,vendor.img}
# These are device images and are never committed (see .gitignore).
#
# Usage: extract-prebuilts.sh <dir with *_live_dump.img> <ANDROID_ROOT>

set -euo pipefail

IMAGES="${1:?images dir}"
ANDROID_ROOT="${2:?android root}"
OUT="${ANDROID_ROOT}/vendor/hisense/hlte730t/prebuilt"
UNPACK="${ANDROID_ROOT}/system/tools/mkbootimg/unpack_bootimg.py"

mkdir -p "${OUT}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# boot.img header v1, empty ramdisk (system-as-root); kernel is Image.gz-dtb
python3 "${UNPACK}" --boot_img "${IMAGES}/boot_live_dump.img" --out "${TMP}" >/dev/null
cp "${TMP}/kernel" "${OUT}/Image.gz-dtb"

cp "${IMAGES}/dtbo_live_dump.img" "${OUT}/dtbo.img"

# Stage 1 vendor: stock vendor + the fixes in device/.../stage1-vendor
rm -f "${OUT}/vendor.img"
"$(dirname "${BASH_SOURCE[0]}")/make-stage1-vendor.sh" \
    "${IMAGES}/vendor_live_dump.img" "${OUT}/vendor.img" >/dev/null

ls -l "${OUT}"
