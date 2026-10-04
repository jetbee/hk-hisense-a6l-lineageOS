<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Hisense A6L (HLTE730T) — hardware notes

Licence: CC BY 4.0

What we learned about the hardware while porting LineageOS 18.1 (Android 11), as groundwork for later Android versions. Items marked **unverified** were not measured directly.

**Sources.** Unless a line says otherwise, every fact here was observed on the device: logcat, dmesg, sysfs, getprop or dumpsys on stock Pie or on the 18.1 port, 2026-09-23…10-02. Other sources are marked as follows:
- *[build]*: the port's own build or config.
- *[stock image]*: the stock system or vendor image, read as files.
- *[analysis]*: inferred from behaviour or from the stock binaries' observable effects.
- *[public]*: public documentation.

No per-device identifiers (IMEI, ICCID, serial, MAC, GSF ID, phone numbers, keys) appear here, and nothing derived from decompiled vendor code is described beyond its observable behaviour.

## 1. Device

| Item | Value |
| --- | --- |
| Model | Hisense A6L, model code HLTE730T |
| SoC | Qualcomm SDM660 (Snapdragon 660), `ro.board.platform=sdm660` |
| Stock OS | Android 9 (Pie), kernel 4.4.153 |
| Port | LineageOS 18.1 with the **stock** 4.4.153 kernel and the stock Pie vendor image (patched, see §10) |
| Boot | Non-A/B. Bootloader unlockable (orange state). the stock vbmeta flashed with `--disable-verity --disable-verification` (flags=3) for the port |
| Storage | eMMC (`/dev/block/mmcblk0`, boot device `c0c4000.sdhci`). Capacity: unverified |
| RAM | Unverified |

### Partitions (names and roles)

Only partitions we touched or that matter to the port are listed; the full GPT has more (QC firmware, `oem_*` and so on).

| Name | Role / notes |
| --- | --- |
| `boot` | Kernel + ramdisk (stock 4.4.153 kernel, LineageOS ramdisk) |
| `dtbo` | Device-tree overlays (stock) |
| `vbmeta` | AVB metadata; flashed with verification disabled |
| `system` | LineageOS system-as-root image |
| `vendor` | Stock Pie vendor, lightly patched (fix1…fix8, §10) |
| `userdata` | `/data`, ext4, file-based encryption on fix7 |
| `metadata` | Present (`mmcblk0p40`); **not used** by the port's fstab. `fastboot -w` erases it |
| `cache` | ext4, small |
| `persist` | `/mnt/vendor/persist`: sensor/Wi-Fi calibration, `time/ats_*` (§8) |
| `modem` | Mounted at `/vendor/firmware_mnt` (vfat) |
| `dsp`, `bluetooth` | Firmware |
| `keystore`, `ssd`, `frp`, `devinfo` | Standard QC/AOSP roles |
| `kdebuginfo` | Hisense debug partition (`mmcblk0p52`, ext4); stock also used `/kdebuginfo/edpd` to hand the E-ink screen-off bitmap to the HWC (§2) |
| `recovery` | Stock recovery |
| EFS (`modemst1/2`, `fsg`, `fsc`) | Modem NV / IMEI. **Back up before anything; never share** |

## 2. Displays

### Front LCD
- 1080 × 2340, panel `ft8719_tianma` (DSI video mode).
- Density **480**. `ro.sf.lcd_density=480` must be in `build.prop`: the stock `init.qcom.early_boot.sh` sets it too late for SurfaceFlinger and you get 213 (tiny UI).
- Backlight: `/sys/class/leds/lcd-backlight/brightness` (`sysfs_graphics`). PowerManager rewrites it on every screen-on and brightness change.

### Back E-ink (EPD)
- 720 × 1440, driven by the **stock vendor HWC** (`hwcomposer.sdm660.so`) plus a software TCON library. The PMIC is a TPS65185 on I²C bus 2.
- It is an **external display (display 1)**. It appears only after hotplug: write `1` to `/sys/class/graphics/fb1/epd_connect` (the port does this from init at `sys.boot_completed=1`).
- Nodes under `/sys/class/graphics/fb1/` (`sysfs_graphics`, system 0666): `epd_connect`, `epd_display_mode`, `epd_display_type`, `epd_force_clear`, `epd_contrast`, `epd_black_threshold`, `epd_white_threshold`, `epd_commit_bitmap`. `epd_info` and `epd_vcom` carry their own labels.
- **Writing `epd_contrast` / `epd_*_threshold` before the EPD is connected crashes the stock HWC** (tombstone: null dereference in its uevent handler), which bootloops system_server. Only write them after `EPD = connected`.
- **Screen-off blanks the E-ink and the HWC never unblanks it.** After any screen-off (power key, timeout, lift-to-wake, fingerprint wake), toggling `epd_connect` 0→1 brings it back. The E-ink service does this on every screen-on.
- `epd_display_mode`: the HWC follows changes immediately. Observed: **8** is the everyday mode; 1 and 2 flash on every update. 0, 3 and 6 were exercised (frames update) but not judged visually. `epd_display_type` writes had no visible effect at runtime.
- Aspect: mirroring 1080×2340 leaves black bars. `wm size 1080x2160` fills the panel exactly (2:1).
- The E-ink keeps its last image without power, so the last screen content stays visible (privacy). The port draws its own status screens ("LCD in use since HH:MM", or a sleep screen with clock, date and battery) through `/kdebuginfo/edpd`. That needs the `kdebuginfo` mount and its SELinux type mapped in vendor policy (fix6).

## 3. Touch

| Panel | Driver | Enable node | Notes |
| --- | --- | --- | --- |
| Front | `ft8719_ts` | `/sys/ctp/ctp_func/tpenable` | The driver **re-enables it (1) on every screen-on**. On 18.1 the node is plain `sysfs` unless vendor policy labels it (vendor policy labels it: fix3/fix4 add `genfscon … vendor_sysfs_ctp_func` for the touch nodes) |
| Back (E-ink) | `ft5x06_ts` | `/sys/ctp1/ctp_func/tpenable` (`vendor_sysfs_ctp_func`) | Value persists across screen off/on. `0` really stops events |

- `ft5x06_ts.idc`: `device.internal = 0` makes it external so it maps to the E-ink viewport. `touch.wake = 0` stops a touch on the back panel from waking the phone while the screen is off (it otherwise shows up as `android.policy:MOTION` wakes).
- If both panels feed display 0 (mirror mode), touching both at once drops the later device's pointer. So the inactive panel must be disabled: back off while on the LCD, front off while E-ink only.

## 4. Buttons and keys

| Key | Source | Notes |
| --- | --- | --- |
| Power, volume | `qpnp_pon`, `gpio-keys` | Standard |
| E-ink switch (back) | `gpio-keys` (event9), **KEY_LEFT_UP (616)** | Kernel logs `HSINFO: EPD_PWR key pressed/released` |
| Fingerprint gestures | `sf-keys` | KEY_TOUCHPAD_* / F11-style keys from the Sunwave sensor |
| Hall / flip | `hall` input device exists | No event observed when flipping the phone (unverified whether a magnet cover triggers it) |

## 5. Fingerprint

- Sunwave sensor, stock vendor HAL `android.hardware.biometrics.fingerprint@2.1` (works unchanged on 18.1).
- Enrollment and unlock need the keymaster HMAC agreement (§9). Without it, gatekeeper verify fails and PIN or fingerprint can't be saved.
- The port's per-finger unlock target (E-ink or LCD) keys off the template ID reported in `onAuthenticated`.

## 6. Cellular

- **DSDS** (`persist.radio.multisim.config=dsds`), two qcril instances. Stock shipped `ro.telephony.default_network=22,22` *[stock image]* (all modes incl. LTE). Without it 18.1 defaults to `0` (WCDMA preferred, no LTE), and LTE-only carriers (Rakuten, au/mineo) show *no service*. Set it in the device tree. Existing per-SIM settings must then be changed by hand.
- **Both slots can be on LTE at the same time** (verified: slot 1 KDDI/mineo + slot 2 Rakuten, `gsm.network.type=LTE,LTE`), with both slots on band mode 6 (below).
  - Slot 2's 2G/3G band preference restricted with **band mode 6 ("Cellular 800")** *[analysis]*. In Japan this effectively turns 2G/3G off, so the modem camps on LTE. The modem keeps the value across reboots. AOSP's `*#*#4636#*#*` "Select radio band" only targets the default phone (slot 1); the port adds `cmd phone band-mode <slot> <mode>` (slot 0 = SIM1) *[build]*.
  - On stock the user also had to choose Cellular 800 for slot 1 to get any service, and that value stayed in the modem (user report).
  - **The deciding factor is the mobile-data SIM** (confirmed with the user): with data on slot 2, both slots are on LTE; with data on slot 1, slot 2 goes out of service. Slot 1 keeps LTE even when it is not the data SIM. *[analysis]* Likely a modem rule that only lets subscription 0 keep LTE as the non-data SIM; not yet confirmed.
  - In practice: keep mobile data on slot 2 when two LTE-only SIMs are used.
- APNs (from the built-in list): Rakuten `rakuten.jp` (IPV4V6). mineo au plan `mineo.jp`, user `mineo@k-opti.com`, CHAP. The AOSP APN list already contains both. Mobile data stays off until setup is completed (`device_provisioned`).
- NITZ from Rakuten and NTP both work (§8).
- **VoLTE on 18.1: physical slot 1 only** (2026-10-04, userdebug-20 carry). With the Qualcomm IMS stack in `vendor/a6l-ims` (not part of this repository), calls on the slot-1 SIM go over IMS: outgoing and incoming calls work and data works during a call. The modem's IMS is pinned to slot 1 (`vendor.ims.activesub=0`), so slot 2 has no VoLTE. Video calling is not available (the vendor RTP service is too old for the 18.1 IMS stack).
- If mobile data is on the slot-2 SIM, using data during a slot-1 VoLTE call can drop the call (the framework re-requests data on slot 2; the RIL is too old for the temporary data switch of Android 11). Keep mobile data on slot 1 when using VoLTE.
- The carrier config shows `carrier_volte_available_bool=false` for a SIM whose carrier has its own carrier-id config file (the mccmnc overlay is not used for it); IMS registration and calls still work.

## 7. Wi-Fi

- QCA WCN (qcacld-3.0), config `/vendor/etc/wifi/WCNSS_qcom_cfg.ini` (the firmware path is a symlink to it).
- 5 GHz hotspot: under the JP country code, W52 (ch 36–48) is indoor-only. With the default `gindoor_channel_support=0` the driver makes those channels passive, so the SoftAP finds no 5 GHz channel. Setting **`gindoor_channel_support=1`** (vendor fix5) and limiting the 5 GHz SoftAP channel list to W52 in the framework overlay gives a working hotspot on ch 40 with country JP. No country-code spoofing is needed.
- The regulatory domain shows the driver's default (CN) while Wi-Fi is off. JP is applied once Wi-Fi or SoftAP starts.
- The PC-side RNDIS issue (Windows dropping Wi-Fi when the phone is tethered over USB) was a Windows setting (`fMinimizeConnections=0`), not the phone.

## 8. Time

- The PMIC RTC (`qpnp_rtc`, rtc0) counts seconds since 1970 and is **not writable** (QC norm). Real time = RTC + an offset kept by the vendor `time_daemon` in `ats_<base>` files.
- `time_daemon` reads them from `/data/vendor/time` (copies also live in `/mnt/vendor/persist/time`). If `ats_1`, `ats_2` and `ats_16` are missing *[analysis]*, it resets the clock to 2018-01-01 (reset value: *[stock image strings]*; the reset itself observed). Android then bumps it to the build time. Result: every boot starts at the build date.
- Wiping `/data` removes those files. Fix: the port copies them from persist once per userdata (i.e. after a wipe), at zygote-start, before time_daemon runs; init cannot test whether a file exists, so a persistent property marks the copy as done *[build]*, and keep `auto_time=1`. Rakuten NITZ and NTP both deliver time.

## 9. Encryption and keystore

- Kernel: ext4/f2fs encryption, PFK, ICE (eMMC `sdcc1ice`, "QC ICE 3.0.72"), dm-crypt, QSEECOM, QCE all built in. No `dm-default-key` (4.4).
- Stock used FDE (`forceencrypt=footer`, `ro.crypto.type=block`). The port first used `encryptable=footer` (unencrypted) to get past the FDE boot stall, then moved to **FBE**: `fileencryption=ice` (vendor fix7), giving `ro.crypto.state=encrypted`, `ro.crypto.type=file`. Switching needs a `/data` wipe.
- Keymaster 4.0 runs in the TrustZone TA (the km3 HAL aborts). Gatekeeper is inside it. On Android 11, the **HMAC key agreement** between keymaster and the other HALs is triggered only by vold (on encrypted devices) or by `wait_for_keymaster` *[public: AOSP source; confirmed on device]*. On an unencrypted `/data` it never ran, so gatekeeper verify failed (error -24) and no PIN or fingerprint could be saved. The port starts `wait_for_keymaster` at late-fs.

## 10. Things that bit us on 18.1 (cause → fix)

| Symptom | Cause | Fix |
| --- | --- | --- |
| FDE setup fails at first boot and `/data` stays read-only | Stock fstab `forceencrypt=footer` (FDE) | `encryptable=footer` (stage-1 vendor fstab patch), later FBE `fileencryption=ice` (fix7) |
| Boot logo stays on screen when powered off with USB connected | Off-mode charging (`androidboot.mode=charger`): the stock vendor defines a `charger` service for `/charger`, which 18.1 lacks; the stock vendor labels the PMIC `power_supply` nodes for healthd only | `hlte730t_charger` service in class `charger`; vendor fix8 lets the charger domain read `sysfs_battery_supply`/`sysfs_usb_supply` |
| No E-ink output | E-ink is an external display needing hotplug | init writes `epd_connect` after boot (fix2: vendor policy lets init write `sysfs_graphics`) |
| Tiny UI | Late `lcd_density` from vendor script | `ro.sf.lcd_density=480` in build.prop |
| Lock screen offers only None/Swipe | Pie `handheld_core_hardware.xml` lacks `android.software.secure_lock_screen` | Ship the Android 11 version in product |
| PIN or fingerprint can't be saved | No keymaster HMAC agreement on unencrypted data | `wait_for_keymaster` at late-fs |
| Firmware not found | `/firmware` symlink missing | `/firmware → /vendor/firmware_mnt` |
| Bootloop after adding E-ink service | Writing EPD contrast/threshold before connect crashes the HWC | Defer writes until after connect and boot complete |
| E-ink frozen after screen-off | HWC never unblanks | Reconnect on every screen-on |
| Both screens on or both touch panels active | Settings written before the LCD power-on finished, then overwritten by driver or PowerManager | Re-apply after screen-on settles |
| Phone wakes by itself in E-ink mode | Back panel (external) wakes the device | `touch.wake = 0` in the idc |
| E-ink keeps the last screen (privacy) | E-ink retains image | Draw a status screen via `/kdebuginfo/edpd` (needs mount + SELinux mapping, fix6) |
| Clock starts at build date | `ats_*` missing in `/data/vendor/time` | Copy from persist at boot |
| Slot 2 / LTE carriers no service | Default network type 0, slot-2 2G/3G band preference | `default_network=22,22`; band mode 6 on both slots; mobile data on slot 2 |
| 5 GHz hotspot fails | W52 passive under JP | `gindoor_channel_support=1` |
| USB vanished after `adb root` right after boot | adbd restart left FunctionFS disabled until replug | Avoid `adb root` immediately after boot; replug fixes it |
| Phone "hangs" (adb gone) while host asleep | Host-side USB suspend | Not a phone issue |

## 11. Open items
- Confirm the modem rule behind "only slot 1 keeps LTE as the non-data SIM", and decide build defaults (band mode, data SIM).
- VoLTE: the data-SIM-on-slot-2 call drop; carrier-id configs for the VoLTE carriers.
- Light and proximity sensors use Hisense-specific sensor types (not yet mapped).
- The Bluetooth MAC is a placeholder (unverified fix).
- RAM and storage sizes, and the full partition table with roles: to fill in.
