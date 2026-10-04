#
# Copyright (C) 2026 The LineageOS Project
# Copyright (C) 2026 jetbee
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from hlte730t device
$(call inherit-product, device/hisense/hlte730t/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_hlte730t
PRODUCT_DEVICE := hlte730t
PRODUCT_BRAND := Hisense
PRODUCT_MODEL := HLTE730T
PRODUCT_MANUFACTURER := Hisense

PRODUCT_GMS_CLIENTID_BASE := android-hisense

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=HLTE730T \
    PRIVATE_BUILD_DESC="HLTE730T-user 9 PKQ1.190723.001 L1632.6.01.04 release-keys"

BUILD_FINGERPRINT := Hisense/HLTE730T/HLTE730T:9/PKQ1.190723.001/L1632.6.01.04:user/release-keys
