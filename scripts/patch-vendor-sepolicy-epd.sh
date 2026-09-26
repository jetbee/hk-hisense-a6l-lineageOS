#!/bin/bash
#
# Stage 1 fix 2 (vendor-fix2): SELinux for the E-ink path, applied to a copy
# of the vendor-fix1 image (see patch-vendor-fstab.sh).
#
# Why: the stock ROM defined epd_flash_device (and its 28.0 mapping) in the
# Hisense-modified *system* policy. LineageOS' platform policy has neither, so
# the stock vendor rule for HWC points at an empty attribute and /dev/epd_flash
# stays labelled "device". Also, epd_connect used to be written by the stock
# system_server; we write it from init instead, which needs an allow rule.
#
# Changes (appended; nothing else in the image changes):
#   vendor_file_contexts: /dev/epd_flash -> graphics_device (HWC can already
#                         read/write graphics_device)
#   vendor_sepolicy.cil:  init may write sysfs_graphics (fb1/epd_connect is
#                         already labelled sysfs_graphics by the stock vendor),
#                         plus the rules in <extra.cil>, if given.
#
# With a LineageOS system the precompiled vendor policy's plat hash no longer
# matches, so init compiles the policy from these .cil files at every boot.
# Must run as root (loop mount).
#
# Usage: patch-vendor-sepolicy-epd.sh <vendor-fix1.img> <output.img> [extra.cil]

set -euo pipefail

SRC="${1:?vendor-fix1 image}"
OUT="${2:?output image}"
EXTRA="${3:-}"
MNT="$(mktemp -d)"
SEL="${MNT}/etc/selinux"

cp --sparse=always "${SRC}" "${OUT}"
mount -o loop,rw "${OUT}" "${MNT}"
trap 'mountpoint -q "${MNT}" && umount "${MNT}"; rmdir "${MNT}"' EXIT

append() {  # append to a file in place, keeping inode, mode, owner, label, mtime
    local f="$1" mtime
    mtime="$(stat -c %Y "${f}")"
    cp "${f}" "${MNT}.orig"
    cat >> "${f}"
    touch -d "@${mtime}" "${f}"
    diff -u "${MNT}.orig" "${f}" || true
    rm -f "${MNT}.orig"
}

append "${SEL}/vendor_file_contexts" <<'EOF'
# hlte730t stage 1: E-ink flash (waveform) device, see patch-vendor-sepolicy-epd.sh
/dev/epd_flash		u:object_r:graphics_device:s0
EOF

{
    echo ';; hlte730t stage 1: E-ink, see patch-vendor-sepolicy-epd.sh'
    echo '(allow init_28_0 sysfs_graphics (file (write open getattr)))'
    [ -n "${EXTRA}" ] && cat "${EXTRA}"
} | append "${SEL}/vendor_sepolicy.cil"

ls -laZ "${SEL}/vendor_file_contexts" "${SEL}/vendor_sepolicy.cil"
umount "${MNT}"
e2fsck -fn "${OUT}"
