#
# Copyright (C) 2026 The LineageOS Project
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

# Optional local E-ink stack ported from the stock firmware. It is not part
# of this repository; without it the build is unchanged.
$(call inherit-product-if-exists, vendor/hisense-private/epd/epd.mk)
