#!/usr/bin/env python3
"""Generate a first-draft proprietary-files.txt from a stock vendor file list.

Usage: gen_proprietary_files.py vendor-files.txt proprietary-files.txt excluded.txt

vendor-files.txt holds one path per line, relative to the vendor partition root
(e.g. lib64/libfoo.so), as produced by `find . -type f` on the mounted image.
Everything kept is emitted as vendor/<path>, grouped by subsystem. Everything
dropped goes to excluded.txt with the reason, so the draft can be reviewed.
"""
import re
import sys

# (reason, regex) — first match wins. Paths are relative to /vendor.
EXCLUDE = [
    ("個体固有・秘密情報の可能性（鍵）", r"^etc/keyboxes"),
    ("ビルドで生成される", r"^(build\.prop|default\.prop|etc/NOTICE\.xml\.gz|etc/fs_config_(dirs|files)|etc/group|etc/passwd|etc/mkshrc)$"),
    ("device tree 側で持つ（sepolicy）", r"^etc/selinux/"),
    ("device tree 側で持つ（VINTF manifest）", r"^etc/vintf/"),
    ("device tree 側で持つ（rootdir の init・fstab・ueventd）", r"^(ueventd\.rc|etc/fstab\.qcom|etc/init/hw/)"),
    ("device tree 側で持つ（public.libraries）", r"^etc/public\.libraries\.txt$"),
    ("RRO は device tree の overlay で作り直す", r"^overlay/"),
    ("VNDK は 18.1 の prebuilts/vndk から入る", r"^lib(64)?/vndk(-sp)?/"),
    ("テスト用バイナリ", r"^bin/qmi-framework-tests/"),
    ("USB ドライバの CD イメージ（端末動作に不要）", r"^etc/Driver\.iso$"),
    ("AOSP のデフォルト実装（ソースからビルドされる）", r"^lib(64)?/hw/(audio\.primary\.default|audio\.r_submix\.default|audio\.usb\.default|gralloc\.default|local_time\.default|power\.default|vibrator\.default|fingerprint\.default)\.so$"),
]

# Kept files that LineageOS 18.1 may build from source instead
# (hardware/qcom-caf/msm8998 covers sdm660). Kept in the draft, flagged.
REVIEW = re.compile(
    r"^lib(64)?/hw/(android\.hardware\.[a-z.]+@[\d.]+-impl\.so|gralloc\.sdm660|hwcomposer\.sdm660|memtrack\.sdm660|audio\.primary\.sdm660|lights\.sdm660|power\.qcom|thermal\.sdm660)"
    r"|^lib(64)?/(libqdMetaData|libqdutils|libqservice|libsdmcore|libsdmutils|libgralloccore|libdisplayconfig|libdrmutils|libtinycompress|libOmx\w+|libstagefrighthw|libc2dcolorconvert|libmm-omxcore|libhdmi|libaudioroute|libqcompostprocbundle|libqcomvisualizer|libqcomvoiceprocessing|libvolumelistener|libreference-ril)\.so$"
    r"|^bin/hw/android\.hardware\.(audio|graphics|memtrack|light|power|thermal|usb|vibrator|configstore|health|media\.omx|cas|drm)"
    r"|^etc/init/android\.hardware\.(audio|graphics|memtrack|light|power|thermal|usb|vibrator|configstore|health|media\.omx|cas|drm)"
)

REVIEW_TITLE = "要検討：LineageOS 18.1 が hardware/qcom-caf/msm8998 からビルドできるなら外す"

# Section title, regex. First match wins; unmatched files go to "その他".
SECTIONS = [
    ("Adreno（GPU）", r"egl/|adreno|libgsl|libllv|libC2D2|libCB\.so|libOpenCL|libq3dtools|libRSDriver|vulkan\.sdm660|libsc-a[23]xx|libEGL_|libGLES"),
    ("Audio", r"acdb|audio|mixer_paths|sound_trigger|listen|soundfx|libaudcal|libadsp|libcsd|libtinyalsa|libsurround|libhwdaemon|graphite_ipc|libqcomvoice|libqcomvisual|libqcompost|libvolumelistener|libadm|liblisten|libcapiv2"),
    ("Camera", r"camera|chromatix|mmcamera|libmmjpeg|libjpeg|lib/image/|libqdMetaData_cam|libmm-qcamera|libactuator|libflash|liboemcamera|libarcsoft|libcamx|libdualcamera|libubifocus|libseemore|libtrueportrait|libchromaflash|liboptizoom"),
    ("Hisense 独自（要確認：E-ink・工場テスト・指紋など）", r"hmct|hisense|\bhx\b|vendor\.hx\.|swfingerprint|sw\.swfingerprint|eink|epd"),
    ("Radio・IMS・QMI", r"qcril|rild|libril|radio/|qmi|libidl|libqcci|libqmiservices|libdiag|libdsi|libdsutils|libconfigdb|libnetmgr|netmgrd|libsystem_health|ims|libimsmedia|liblqe|libmdm|libperipheral|pd-mapper|rmt_storage|tftp_server|libmdmdetect|libsettings|libvendorconn|libqti-util|libxml|librmnetctl|libtime_genoff|time_daemon|qti$|vendor\.qti\.hardware\.radio|mbn|lib/rfsa|libqsocket|libqrtr|qrtr|rfs/"),
    ("CNE・データ", r"cne|libwqe|libxtwifi|datamodule|dpm|libdpm|ipacm|IPACM|libhardware_legacy_qti|data/"),
    ("GNSS・位置情報", r"gps|gnss|izat|lowi|flp|\bloc|libloc|liblbs|libgeofence|libgdtap|libizat|libxtadapter|libasn1|sap\.conf|apdr|libflp|slim|libdataitems|liblowi|libbatching|libevent_observer|libgps"),
    ("DRM・Widevine・セキュリティ", r"drm|widevine|keymaster|gatekeeper|keystore|qseecom|libQSEEComAPI|qteeconnector|soter|libspcom|libssd|libops|libdrmfs|libdrmtime|libSecureUILib|libGPreqcancel|libGPTEE|libqisl|libspl|sec_config|esepowermanager|tui_comm|libsecureui|mediacas|mediadrm|qcdrm|trustzone|TrustZone|libStDrvInt|qsee|hdcp|librpmb|libtrustedui|libthermalclient|cacert"),
    ("ディスプレイ・性能・電源", r"display|qdcm|libsdm|hwcomposer|gralloc|memtrack|perf|libqti-perfd|iop|libqti-iopd|power|thermal|msm_irqbalance|irqbalance|libscve|scve|hbtp|libhbtp|lights|libmm-disp|libmm-als|libdisp|libqdutils|libqservice|libtinyxml|libadaptive|vendor\.display"),
    ("メディア（コーデック）", r"media_codecs|media_profiles|libOmx|omx|libstagefright|libmm-omx|libc2d|libavenhancements|libFileMux|libmmparser|libmmosal|libmm-color|libvpp|libfastcv|libhevc|libswvdec|libdivx|libqmp|libextmedia|video|codec"),
    ("センサー", r"sensor|libssc|libsns|activity_recognition|libAR|libsensor|libfastrpc|libadsprpc|libcdsprpc|libmdsprpc|lib/dsp/|dsp/"),
    ("Wi-Fi・Bluetooth・FM・ANT", r"wifi|wlan|WCNSS|hostapd|wpa|cnss|libwpa|bluetooth|bt_|btnv|libbt|ant@|\bant\b|fm@|\bfm\b|libfm|wcnss|qca_cld|init\.qti\.fm"),
    ("ファームウェア", r"^firmware/"),
    ("カーネルモジュール（純正カーネルと組で使う）", r"^lib/modules/"),
    ("アプリ", r"^app/"),
]

ORDER = [t for t, _ in SECTIONS] + ["その他", REVIEW_TITLE]


def main(src, out, excl):
    paths = [l.strip() for l in open(src) if l.strip()]
    sections = {title: [] for title, _ in SECTIONS}
    sections["その他"] = []
    sections[REVIEW_TITLE] = []
    excluded = []
    for p in paths:
        reason = next((r for r, rx in EXCLUDE if re.search(rx, p)), None)
        if reason:
            excluded.append((reason, p))
            continue
        title = next((t for t, rx in SECTIONS if re.search(rx, p, re.I)), "その他")
        entry = "vendor/" + p
        if p.startswith("app/") and p.endswith(".apk"):
            entry += ";PRESIGNED"
        if REVIEW.search(p):
            title = REVIEW_TITLE
        sections[title].append(entry)

    with open(out, "w") as f:
        f.write("# Hisense A6L (HLTE730T) proprietary files — 初版（自動生成）\n")
        f.write("# 出典: 実機 vendor パーティション L1632.6.01.04\n")
        f.write("#   ro.vendor.build.fingerprint=Hisense/HLTE730T/HLTE730T:9/PKQ1.190723.001/L1632.6.01.04:user/release-keys\n")
        f.write("# 生成: scripts/gen_proprietary_files.py（除外したものと理由は excluded.txt）\n")
        for title in ORDER:
            items = sections[title]
            if not items:
                continue
            f.write(f"\n# {title}\n")
            for entry in sorted(items):
                f.write(entry + "\n")
    with open(excl, "w") as f:
        for reason, p in sorted(excluded):
            f.write(f"{reason}\tvendor/{p}\n")

    kept = sum(len(v) for v in sections.values())
    print(f"kept={kept} excluded={len(excluded)}")
    for title in ORDER:
        print(f"  {len(sections[title]):5d}  {title}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
