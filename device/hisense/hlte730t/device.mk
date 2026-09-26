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

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

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
