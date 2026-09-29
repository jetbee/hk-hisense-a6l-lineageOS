#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/hisense/hlte730t
VENDOR_PATH := vendor/hisense/hlte730t

# See device.mk: stage 1 uses the stock vendor image as-is.
TARGET_HLTE730T_PREBUILT_VENDOR ?= true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo

# Platform
# BOARD_USES_QCOM_HARDWARE is left unset on purpose: no CAF HALs are built,
# the display stack comes from the stock blobs (the E-ink path only exists in
# the stock hwcomposer.sdm660.so).
TARGET_BOARD_PLATFORM := sdm660
TARGET_BOOTLOADER_BOARD_NAME := sdm660
TARGET_NO_BOOTLOADER := true

# Kernel: stock 4.4.153 Image.gz-dtb (2 DTBs appended) from boot.img
# (L1632.6.01.04). Put in place by scripts/extract-prebuilts.sh.
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_SECOND_OFFSET := 0x00f00000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_BOOT_HEADER_VERSION := 1
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0 earlycon=msm_serial_dm,0xc170000 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 sched_enable_hmp=1 sched_enable_power_aware=1 service_locator.enable=1 swiotlb=1 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset $(BOARD_KERNEL_OFFSET) --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --second_offset $(BOARD_SECOND_OFFSET) --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
TARGET_PREBUILT_KERNEL := $(VENDOR_PATH)/prebuilt/Image.gz-dtb
BOARD_PREBUILT_DTBOIMAGE := $(VENDOR_PATH)/prebuilt/dtbo.img
BOARD_INCLUDE_RECOVERY_DTBO := true

# Partitions (sizes from the device's GPT, see docs/DEVICE.md; no A/B)
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 6442450944
BOARD_VENDORIMAGE_PARTITION_SIZE := 1153433600
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Launched with Android 9: system-as-root, vendor on its own partition
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

ifeq ($(TARGET_HLTE730T_PREBUILT_VENDOR),true)
BOARD_PREBUILT_VENDORIMAGE := $(VENDOR_PATH)/prebuilt/vendor.img
else
-include $(VENDOR_PATH)/BoardConfigVendor.mk
endif

# Verified boot: the stock DT marks vendor with "avb" and lists vbmeta parts.
# We do not sign; flash the stock vbmeta with verification disabled
# (fastboot --disable-verity --disable-verification flash vbmeta ...).
BOARD_AVB_ENABLE := false

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true

# Root symlinks: the stock vendor (and its fingerprint HAL) expects /firmware,
# which stock pointed at the modem firmware mount.
BOARD_ROOT_EXTRA_SYMLINKS += /vendor/firmware_mnt:/firmware

# Treble
BOARD_VNDK_VERSION := current

# Dexpreopt: under Rosetta (x86_64 Linux in OrbStack on Apple Silicon) dex2oat
# cannot map the boot image below 4 GB and aborts, so preopt is turned off
# there. Android 11 only allows that for eng builds. On a native x86_64 host
# nothing changes (userdebug + dexpreopt). See README.md.
ifneq ($(shell test -e /proc/sys/fs/binfmt_misc/rosetta && echo rosetta),)
WITH_DEXPREOPT := false
ifneq ($(TARGET_BUILD_VARIANT),eng)
$(error Rosetta build host: dexpreopt must be off, which needs an eng build. Use: breakfast hlte730t eng)
endif
endif

# SELinux: system policy only in stage 1; the stock vendor image carries its
# own vendor policy (built against plat 28.0, which 18.1 still maps).
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_PLAT_PRIVATE_SEPOLICY_DIR += $(DEVICE_PATH)/sepolicy/private
