#!/bin/bash
# Copyright (C) 2026 jetbee
# SPDX-License-Identifier: Apache-2.0
#
# Stage 1 fix: make a copy of the stock vendor image whose /vendor/etc/fstab.qcom
# does not force-encrypt userdata. Nothing else in the image changes.
#
#   forceencrypt=footer -> encryptable=footer   (FDE setup fails on 18.1 and
#                                                 /data stays read-only)
#   ,crashcheck         -> removed              (Hisense-specific fs_mgr flag)
#
# The file is rewritten in place, so its inode, mode, owner, SELinux label and
# mtime stay as in the stock image. The stock image itself is not modified.
# Must run as root (loop mount).
#
# Usage: patch-vendor-fstab.sh <stock vendor.img> <output vendor.img>

set -euo pipefail

SRC="${1:?stock vendor image}"
OUT="${2:?output image}"
MNT="$(mktemp -d)"
FSTAB="${MNT}/etc/fstab.qcom"

cp --sparse=always "${SRC}" "${OUT}"
mount -o loop,rw "${OUT}" "${MNT}"
trap 'mountpoint -q "${MNT}" && umount "${MNT}"; rmdir "${MNT}"' EXIT

MTIME="$(stat -c %Y "${FSTAB}")"
cp "${FSTAB}" "${MNT}.orig"
sed -e '/[[:space:]]\/data[[:space:]]/ s/forceencrypt=footer/encryptable=footer/' \
    -e '/[[:space:]]\/data[[:space:]]/ s/,crashcheck//' "${MNT}.orig" > "${MNT}.new"
cat "${MNT}.new" > "${FSTAB}"     # same inode: keeps mode, owner, xattrs
touch -d "@${MTIME}" "${FSTAB}"

diff -u "${MNT}.orig" "${FSTAB}" || true
ls -laZ "${FSTAB}"
rm -f "${MNT}.orig" "${MNT}.new"

umount "${MNT}"
e2fsck -fn "${OUT}"
