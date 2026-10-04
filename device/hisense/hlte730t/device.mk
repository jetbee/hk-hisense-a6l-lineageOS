#
# Copyright (C) 2026 jetbee
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/hisense/hlte730t

# Stage 1 (default): flash the untouched stock vendor partition next to a
# LineageOS system image, GSI-style. This answers the biggest open question
# first: does the stock Android 9 HWC/gralloc (which carries the E-ink path)
# work with the 18.1 SurfaceFlinger?
# Stage 2: build the vendor image from the extracted blobs instead.
TARGET_HLTE730T_PREBUILT_VENDOR ?= true

# Development builds: adb is up and root from the first boot, with no setup
# wizard, no USB debugging toggle and no key prompt, so early boot logs can be
# pulled even right after a userdata wipe. This makes the device insecure:
# anyone with a USB cable gets a root shell. Off by default; turn on for
# development builds only, with HLTE730T_DEV_ADB=true.
HLTE730T_DEV_ADB ?= false
ifeq ($(HLTE730T_DEV_ADB),true)
# vendor/lineage/config/common.mk then sets ro.adb.secure=0, and the build
# adds adb to persist.sys.usb.config (post_process_props.py). Must be set
# before common.mk is inherited, which lineage_hlte730t.mk does after this.
WITH_ADB_INSECURE := true
# adbd starts as root (debuggable build only); bypasses the Lineage
# "Rooted debugging" setting, which lives in /data and is lost on a wipe.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.dev-adb.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.dev-adb.rc
endif

# Launched with Android 9 (Pie); vendor is built against VNDK v28.
PRODUCT_SHIPPING_API_LEVEL := 28
PRODUCT_EXTRA_VNDK_VERSIONS := 28

# Screen: 6.53" 2340x1080 LCD (the 1440x720 E-ink panel is the secondary)
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
TARGET_SCREEN_HEIGHT := 2340
TARGET_SCREEN_WIDTH := 1080

# The stock vendor only sets ro.sf.lcd_density from init.qcom.rc once
# early_boot.sh has probed the panel (480 for this one); the 18.1
# SurfaceFlinger reads it before that and falls back to 213.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.sf.lcd_density=480

# Telephony: default network type of both SIM slots, as stock system.prop
# (22 = NETWORK_MODE_TD_SCDMA_LTE_CDMA_EVDO_GSM_WCDMA, every RAT incl. LTE).
# Unset, 18.1 falls back to 0 (WCDMA preferred, no LTE).
PRODUCT_PRODUCT_PROPERTIES += \
    ro.telephony.default_network=22,22

# Features: the stock (Android 9) vendor handheld_core_hardware.xml predates
# android.software.secure_lock_screen, without which Settings offers no
# PIN/pattern/password (and so no fingerprint enrollment). The 18.1 copy adds
# it, plus software.controls; the sensors it lists are declared by the stock
# sensor_features.xml anyway.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/handheld_core_hardware.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# E-ink: connect the EPD as HWC display 1 after boot
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.epd-connect.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.epd-connect.rc

# E-ink side touch: enable it after boot, and mark it external (as stock
# does) so input is associated with the external (E-ink) display
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.ctp1.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.ctp1.rc \
    $(DEVICE_PATH)/rootdir/usr/idc/ft5x06_ts.idc:$(TARGET_COPY_OUT_SYSTEM)/usr/idc/ft5x06_ts.idc

# Keymaster: run HMAC key agreement at boot (nothing else does while userdata
# is unencrypted), or gatekeeper cannot verify and no screen lock can be set
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.keymaster.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.keymaster.rc

# kdebuginfo: relabel the stock debug partition once it is mounted (the
# E-ink HWC reads its screen-off bitmap from there)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.kdebuginfo.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.kdebuginfo.rc

# Time: seed the time_daemon offsets from persist once per userdata, or the
# clock starts at 2018-01-01 after a wipe
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.time.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.hlte730t.time.rc

# Wi-Fi: 5 GHz and ACS for the hotspot, 5 GHz SoftAP limited to W52
PRODUCT_PACKAGES += \
    WifiOverlay

# Keep in sync with BoardConfig.mk (product and board makefiles do not share
# plain variables). Override both with TARGET_HLTE730T_PREBUILT_VENDOR=false.
ifneq ($(TARGET_HLTE730T_PREBUILT_VENDOR),true)
# Init: E-ink permissions transcribed from the stock init.bsp.rc. With the
# prebuilt stock vendor (stage 1) the original file is already there.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom \
    $(DEVICE_PATH)/rootdir/etc/init.hlte730t.eink.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.hlte730t.eink.rc

# Proprietary blobs
$(call inherit-product, vendor/hisense/hlte730t/hlte730t-vendor.mk)
endif

# VoLTE (IMS, voice only). The Qualcomm IMS apps and libraries are not part
# of this repository; they are expected in vendor/a6l-ims (taken from the
# official LineageOS 18.1 SDM660 blobs). Without them the build has no
# VoLTE, and the settings below are harmless.
DEVICE_PACKAGE_OVERLAYS += $(DEVICE_PATH)/overlay
PRODUCT_PACKAGES += \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-hidl-wrapper \
    qti_telephony_hidl_wrapper.xml \
    qti-telephony-utils \
    qti_telephony_utils.xml \
    telephony-ext
PRODUCT_BOOT_JARS += \
    telephony-ext
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.telephony.ims.xml
PRODUCT_PRODUCT_PROPERTIES += \
    persist.dbg.volte_avail_ovr=1 \
    persist.dbg.vt_avail_ovr=0 \
    persist.dbg.wfc_avail_ovr=0
$(call inherit-product-if-exists, vendor/a6l-ims/ims.mk)

# Google apps: MindTheGapps (branch rho for 11), synced by hand to vendor/gapps
# outside this repository. Without it the build has no GApps.
$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)

# E-ink stack (the "epd" service, E-ink key, status screen): a6l-eink, a
# clean-room implementation synced to vendor/a6l-eink. Without it the build
# has no E-ink switching.
$(call inherit-product-if-exists, vendor/a6l-eink/epd/epd.mk)
