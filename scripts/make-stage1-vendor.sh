#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
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
#   /etc/wifi/WCNSS_qcom_cfg.ini       + WCNSS_qcom_cfg.ini.add, inserted before
#                                      END (the driver stops reading there)
# Each rewritten file keeps the stock mode, owner, timestamps and
# security.selinux label; nothing else in the image changes.
#
# Needs e2fsprogs 1.46 or newer (debugfs, e2fsck) on the host. debugfs 1.45.5
# (Ubuntu 20.04, e.g. an older build container) takes the full path given to
# "write" as a file name and creates "/etc/fstab.qcom" in the root directory,
# which breaks the image; run this script on a host with a newer debugfs.
#
# With STAGE1_KEYMASTER=3.0 the image also switches keymaster from the stock
# 4.0 service to the 3.0 one that stock ships unused (bin and impl are there):
# the manifest entry becomes 3.0 and the 4.0 rc starts the 3.0 service. This
# is the pairing the official 18.1 Asus SDM660 trees use with gatekeeper-qti.
#
# With STAGE1_FBE=1 userdata gets file-based encryption with the eMMC inline
# crypto engine instead (forceencrypt=footer -> fileencryption=ice), as the
# official 18.1 SDM660 trees on kernel 4.4 do. No metadata encryption: the
# stock kernel has no dm-default-key. Needs a userdata wipe when switching.
#
# Usage: [STAGE1_KEYMASTER=3.0] [STAGE1_FBE=1] make-stage1-vendor.sh <stock vendor.img> <output vendor.img>

set -euo pipefail

# debugfs older than 1.46 writes the files under wrong names (see above).
dfs_ver="$(debugfs -V 2>&1 | sed -n 's/^debugfs \([0-9][0-9.]*\).*/\1/p' | head -1)"
if [ -z "${dfs_ver}" ] || [ "$(printf '%s\n' 1.46 "${dfs_ver}" | sort -V | head -1)" != 1.46 ]; then
    echo "make-stage1-vendor.sh: debugfs ${dfs_ver:-(not found)} is too old; need 1.46 or newer" >&2
    exit 1
fi

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
if [ "${STAGE1_FBE:-0}" = 1 ]; then
    userdata_crypt=fileencryption=ice
else
    userdata_crypt=encryptable=footer
fi
sed -e "/[[:space:]]\/data[[:space:]]/ s/forceencrypt=footer/${userdata_crypt}/" \
    -e '/[[:space:]]\/data[[:space:]]/ s/,crashcheck//' "${TMP}/fstab.qcom" > "${TMP}/fstab.qcom.new"
replace /etc/fstab.qcom "${TMP}/fstab.qcom.new"

for f in vendor_file_contexts vendor_sepolicy.cil; do
    dfs "dump /etc/selinux/${f} ${TMP}/${f}" >/dev/null
    cat "${TMP}/${f}" "${DATA}/${f}.append" > "${TMP}/${f}.new"
    replace "/etc/selinux/${f}" "${TMP}/${f}.new"
done

dfs "dump /etc/wifi/WCNSS_qcom_cfg.ini ${TMP}/wcnss.ini" >/dev/null
grep -qx 'END' "${TMP}/wcnss.ini"
awk -v add="${DATA}/WCNSS_qcom_cfg.ini.add" '
    $0 == "END" && !done { while ((getline l < add) > 0) print l; done = 1 }
    { print }' "${TMP}/wcnss.ini" > "${TMP}/wcnss.ini.new"
replace /etc/wifi/WCNSS_qcom_cfg.ini "${TMP}/wcnss.ini.new"

case "${STAGE1_KEYMASTER:-4.0}" in
4.0) ;;
3.0)
    dfs "dump /etc/vintf/manifest.xml ${TMP}/manifest.xml" >/dev/null
    python3 - "${TMP}/manifest.xml" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
hal = re.compile(r'(<hal format="hidl">\s*<name>android\.hardware\.keymaster</name>.*?</hal>)', re.S)
blocks = hal.findall(s)
assert len(blocks) == 1, "expected one keymaster HAL entry"
new = blocks[0].replace("<version>4.0</version>", "<version>3.0</version>") \
               .replace("@4.0::IKeymasterDevice/default", "@3.0::IKeymasterDevice/default")
assert new != blocks[0]
open(p, "w").write(s.replace(blocks[0], new))
PY
    replace /etc/vintf/manifest.xml "${TMP}/manifest.xml"
    cat > "${TMP}/keymaster.rc" <<'RC'
service keymaster-3-0 /vendor/bin/hw/android.hardware.keymaster@3.0-service-qti
    class early_hal
    user system
    group system drmrpc
RC
    replace /etc/init/android.hardware.keymaster@4.0-service-qti.rc "${TMP}/keymaster.rc"
    ;;
*)
    echo "make-stage1-vendor.sh: STAGE1_KEYMASTER must be 4.0 or 3.0" >&2
    exit 1
    ;;
esac

e2fsck -fn "${OUT}"
