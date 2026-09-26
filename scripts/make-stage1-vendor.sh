#!/bin/bash
#
# Build the stage 1 vendor image (what was flashed as "vendor-fix2") from the
# untouched stock vendor dump, without root: debugfs edits the ext4 image.
#
# Changes, all kept in device/hisense/hlte730t/stage1-vendor/:
#   /etc/fstab.qcom                    userdata: forceencrypt=footer ->
#                                      encryptable=footer, drop crashcheck
#                                      (FDE setup fails on 18.1, /data stays ro)
#   /etc/selinux/vendor_file_contexts  + vendor_file_contexts.append
#                                      (/dev/epd_flash -> graphics_device)
#   /etc/selinux/vendor_sepolicy.cil   + vendor_sepolicy.cil.append
#                                      (init may write sysfs_graphics; HWC may
#                                      read system_prop/default_prop)
# Each rewritten file keeps the stock mode, owner, timestamps and
# security.selinux label; nothing else in the image changes.
#
# Needs e2fsprogs (debugfs, e2fsck) on the host.
#
# Usage: make-stage1-vendor.sh <stock vendor.img> <output vendor.img>

set -euo pipefail

SRC="${1:?stock vendor image}"
OUT="${2:?output image}"
DATA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../device/hisense/hlte730t/stage1-vendor" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

dfs() { debugfs -R "$1" "${OUT}" 2>/dev/null; }

# Replace <path> in the image with <newfile>, copying mode, owner, times and
# the SELinux label from the stock inode.
replace() {
    local path="$1" new="$2" st mode uid gid t
    st="$(dfs "stat ${path}")"
    mode="$(sed -n 's/.*Mode: *\([0-7]*\).*/\1/p' <<<"${st}" | head -1)"
    uid="$(sed -n 's/.*User: *\([0-9]*\).*/\1/p' <<<"${st}" | head -1)"
    gid="$(sed -n 's/.*Group: *\([0-9]*\).*/\1/p' <<<"${st}" | head -1)"
    debugfs -R "ea_get -f ${TMP}/label ${path} security.selinux" "${OUT}" >/dev/null 2>&1
    {
        echo "rm ${path}"
        echo "write ${new} ${path}"
        echo "sif ${path} mode 0100${mode}"
        echo "sif ${path} uid ${uid}"
        echo "sif ${path} gid ${gid}"
        for t in atime ctime mtime crtime; do
            echo "sif ${path} ${t} @$(sed -n "s/^ *${t}: *\(0x[0-9a-f]*\).*/\1/p" <<<"${st}" | head -1)"
            echo "sif ${path} ${t}_extra 0"
        done
        echo "ea_set -f ${TMP}/label ${path} security.selinux"
    } > "${TMP}/cmds"
    debugfs -w -f "${TMP}/cmds" "${OUT}" >/dev/null 2>&1
}

cp --sparse=always "${SRC}" "${OUT}"

dfs "dump /etc/fstab.qcom ${TMP}/fstab.qcom" >/dev/null
sed -e '/[[:space:]]\/data[[:space:]]/ s/forceencrypt=footer/encryptable=footer/' \
    -e '/[[:space:]]\/data[[:space:]]/ s/,crashcheck//' "${TMP}/fstab.qcom" > "${TMP}/fstab.qcom.new"
replace /etc/fstab.qcom "${TMP}/fstab.qcom.new"

for f in vendor_file_contexts vendor_sepolicy.cil; do
    dfs "dump /etc/selinux/${f} ${TMP}/${f}" >/dev/null
    cat "${TMP}/${f}" "${DATA}/${f}.append" > "${TMP}/${f}.new"
    replace "/etc/selinux/${f}" "${TMP}/${f}.new"
done

e2fsck -fn "${OUT}"
