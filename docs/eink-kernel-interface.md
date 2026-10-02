# E-ink kernel interface

Licence: CC BY 4.0

> **要約（日本語）**：Hisense A6L（hlte730t、SDM660）の純正カーネル（4.4.153）が、裏の E-ink のために見せている口（fb1 の sysfs、uevent、`/dev/epd_flash`、TPS65185 の sysfs、前面ライト、タッチの切り替え、ボタン）の一覧。4.19 などで E-ink のドライバーを作り直すときに、純正と同じ口を用意するための約束ごととしてまとめた。外から見える約束ごと（名前、パス、権限、値、形式）だけを書き、実装の中身は書いていない。

This document lists the interfaces that the stock Hisense A6L (hlte730t, SDM660) kernel (`4.4.153-perf`) exposes for the rear E-ink panel. It is meant as a contract for re-implementing the E-ink kernel support (for example on a 4.19 kernel) so that the stock userspace sees the same interfaces.

Only externally visible contracts are described: names, paths, permissions, values and formats. Nothing here describes how the stock drivers are implemented.

See also: [eink-display-pipeline.md](eink-display-pipeline.md) for how the stock display stack uses these interfaces.

## Source tags

| Tag | Meaning |
| --- | --- |
| **[device]** | Read or exercised on a device running the stock firmware or the LineageOS 18.1 port |
| **[DTB]** | Value from the device tree blob appended to the stock `boot.img` |
| **[sysfs-attr]** | Attribute name and permission bits as registered by the stock kernel (`struct attribute`) |
| **[str]** | String found in a stock binary (kernel, `hwcomposer.sdm660.so`, `libtcon_eink.so`) |
| **[public]** | Public source (mainline Linux, mailing lists, datasheets) |
| **[guess]** | Inference from the above; not verified |

## 1. Overview

```
HWC (hwcomposer.sdm660.so) ── libtcon_eink.so
   │ /dev/graphics/fb1 (fbdev, DSI1 video panel)
   │ /sys/class/graphics/fb1/epd_*
   │ uevents EPD_CONNECT / EPD_CONTROL
   │ /dev/epd_flash (waveform flash on SPI)
   │ /sys/devices/soc/c176000.i2c/i2c-2/2-0068/{vcom,thermal} (TPS65185)
Other users: fb1 epd_* attributes, /sys/ctp{,1}/ctp_func/tpenable, leds/epd-backlight
```

All E-ink related kernel support is built in; none of it is a loadable module. The waveform flash driver registers under the name `epd_spi`. [str]

## 2. fb1 (E-ink panel)

### 2.1 Device

| Item | Value | Source |
| --- | --- | --- |
| Device node | `/dev/graphics/fb1`; the HWC falls back to `/dev/fb1` (log: `cannot open /dev/graphics/fb1, retrying with /dev/fb1`) | [str] |
| sysfs | `/sys/class/graphics/fb1/` (real path `/sys/devices/virtual/graphics/fb1/`) | [str], [device] |
| Driver | Qualcomm MDSS fbdev, with extra E-ink attributes | [sysfs-attr] |
| Panel node | `qcom,mdss_dsi_epd_eink_qhd_video`, name `eink epd qhd`, `dsi_video_mode`, destination `display_2` (DSI1) | [DTB] |
| fb1 geometry | 384 × 725, 24 bpp, 85 Hz DSI video timing. This differs from the visible E-ink resolution, so fb1 most likely carries data already re-arranged for the panel's timing controller | [DTB], [guess] |
| Physical size | 68 × 121 mm | [DTB] |
| fb1 type string | `mipi dsi video panel` | [device] |
| Visible resolution | 720 × 1440; Android sees it as an external display (displayId 1) | [device] |
| Panel | ED058TC7U2 (from `epd_info`); the SPI flash node in the DT is named `eink,ed052tc2` | [device], [DTB] |

E-ink GPIOs on the DSI1 controller node (`qcom,mdss_dsi_ctrl1@c996000`), all on the TLMM: [DTB]

| DT property | GPIO | Purpose (from the name) |
| --- | --- | --- |
| `qcom,platform-epd-power-on-gpio` | 42 | E-ink power |
| `qcom,platform-epd-xon-gpio` | 61 | XON |
| `qcom,platform-epd-i2c-en` | 56 | Enable for the I2C side (TPS65185) |

The front light is PWM-controlled: `qcom,mdss-dsi-bl-pmic-control-type = bl_ctrl_pwm`, `qcom,mdss-dsi-pwm-gpio`, 54 kHz. [DTB]

### 2.2 sysfs attributes (`/sys/class/graphics/fb1/`)

Permissions are as registered by the stock kernel. [sysfs-attr]

| Name | Mode | Values and meaning | Source |
| --- | --- | --- | --- |
| `epd_connect` | 0644 | Connects the E-ink as an external display. Writing `1` makes the kernel emit the uevent `EPD_CONNECT=1`. Read as `2` on the stock firmware (Android 9, rooted) during the initial survey; the panel state at that moment was not recorded. The 18.1 port writes only `0` and `1`; when waking from screen-off, a `0` → `1` rewrite was needed | [sysfs-attr], [str], [device] |
| `epd_display_type` | 0644 | Front/rear state: `0` front only, `1` front plus independent rear content, `2` rear mirrors front, `4` rear only (LCD off), `-1` both off. Writing it on a running system had no visible effect at the time | [str], [device] |
| `epd_display_mode` | 0644 | Display (waveform) mode. `0`, `1`, `2`, `3`, `6` and `8` were tried; the display follows each immediately. `1` and `2` flash a lot; `8` is the most usable for normal Android use. Frames in 20 s: 0:39, 1:67, 2:34, 3:34, 6:84, 8:74 | [str], [device] |
| `epd_force_clear` | 0644 | Write to request a full refresh that clears ghosting | [str], [device] |
| `epd_commit_bitmap` | 0644 | Writing `1` shows the bitmap image (section 2.6) | [sysfs-attr], [device] |
| `epd_info` | 0644 | Panel information. Read on the stock firmware: panel ED058TC7U2, waveform version 2.2, VCOM 2520 | [str], [device] |
| `epd_vcom` | 0644 | VCOM value | [sysfs-attr] |
| `epd_contrast` | 0644 | Contrast | [sysfs-attr] |
| `epd_black_threshold` | 0644 | Black threshold | [sysfs-attr] |
| `epd_white_threshold` | 0644 | White threshold | [sysfs-attr] |

### 2.3 uevents

| String | Emitted by | Meaning | Source |
| --- | --- | --- | --- |
| `EPD_CONNECT=1` | kernel (fb1) | The E-ink was connected | [str] (kernel and HWC) |
| `EPD_CONTROL=%d` | kernel (fb1) | E-ink control notification; integer value | [str] (kernel and HWC) |

The HWC listens for `change@/devices/virtual/graphics/fb0` and `change@/devices/virtual/graphics/fb1`. [str]
The meaning of each `EPD_CONTROL` value has not been verified.

### 2.4 E-ink button

| Item | Value | Source |
| --- | --- | --- |
| DT | `gpio_keys/epd_pwr`: `label = "epd_pwr"`, `linux,code = 0x268`, wakeup, debounce 15 ms | [DTB] |
| Key code | **`KEY_LEFT_UP` (616)**, not F18 | [DTB], [device] |
| Input device | gpio-keys (event9 on the device) | [device] |
| Kernel log | `HSINFO: EPD_PWR key` | [device] |

### 2.5 Front light (`leds/epd-backlight`)

| Item | Value | Source |
| --- | --- | --- |
| Path | `/sys/class/leds/epd-backlight/` (standard LED class) | [str], [device] |

### 2.6 Bitmap image

| Item | Value | Source |
| --- | --- | --- |
| File | `/kdebuginfo/edpd/bitmap.raw` | [str] |
| Format | 720 × 1440, RGB565 little-endian, no header, 2,073,600 bytes | [device] |
| Commit | Write `1` to `epd_commit_bitmap` | [device] |
| Conditions | Shown only after the E-ink has been blanked by screen-off. While the LCD is in use, only after display 1 has been powered off through SurfaceFlinger. Not accepted in normal mode (matches the log string `epd is normal mode,can not commit bitmap`) | [device], [str] |

The LineageOS 18.1 port uses this for its status screens (sleep and "LCD in use"); see `docs/epd-service.md` in a6l-eink.

## 3. `/dev/epd_flash` (waveform flash)

| Item | Value | Source |
| --- | --- | --- |
| Device | `/dev/epd_flash`, character device, driver name `epd_spi` | [str] |
| Bus | `eink,ed052tc2@0` under `spi@c1b8000` (`qcom,spi-qup-v2`), max 19.2 MHz | [DTB] |
| Contents | SPI NOR flash on the panel side holding the waveform and panel information | [device] |
| User | Read by the HWC at start-up (log strings `ReadEpdFlash open error`, `ReadEpdFlash read error` on failure) | [str] |

The read offset and size contract has not been verified. When re-implementing, dump the whole device on stock and compare.

## 4. TPS65185 (E-ink power IC)

| Item | Value | Source |
| --- | --- | --- |
| DT | `i2c@c176000/tps65185@68`, `compatible = "ti,tps65185"` | [DTB] |
| sysfs | `/sys/devices/soc/c176000.i2c/i2c-2/2-0068/` | [str] |
| `vcom` | 0644. Written by the HWC (log string `Failed to write into epd vcom node` on failure). 2520 on the device | [sysfs-attr], [str], [device] |
| `thermal` | 0444. Panel temperature, read by the HWC. `31` on the device | [sysfs-attr], [str], [device] |
| Other attributes | `temperature` (0444), `power_en` | [sysfs-attr], [device] |
| GPIOs (TLMM) | `tps65185,pm-pwrup-gpio` 35, `pm-pwrcom-gpio` 3, `pm-power-en` 2, `pm-wake-up` 80, `pm-state-gpio` 0 | [DTB] |
| pinctrl | `tps65185_default`, `tps65185_sleep` (`pmx_tps65185`, `pmx_tps65185_state`) | [DTB] |

The HWC also reads `/sys/class/thermal/thermal_zone3/temp` as a second temperature. [str]

**Note:** the path contains the bus number `i2c-2`. On a new kernel, keep the bus number (DT alias) or provide a symlink at the same path.

A TPS65185 regulator driver was posted for mainline Linux for the PineNote ([public]: [regulator: Add TPS65185, v3](https://ratatoskr.run/linux-devicetree/2026/01/3350509/t); [arm64: dts: rockchip: Add TPS65185 for PineNote](https://ratatoskr.run/linux-rockchip/2026/01/3379709/t), January 2026). Check its merge status before relying on it. A port must still expose `vcom` and `thermal` under the names above.

## 5. Touch (front and rear)

| Item | Front (LCD) | Rear (E-ink) | Source |
| --- | --- | --- | --- |
| DT | `i2c@c178000/focaltech@38` (`focaltech,ft8xxx`) | `i2c@c1b7000/focaltech@38` (`focaltech,5x06`, pinctrl `pmx_sub_ts_*`) | [DTB] |
| Input device | — | `ft5x06_ts` (event2 on the device) | [device] |
| Enable switch | `/sys/ctp/ctp_func/tpenable` | `/sys/ctp1/ctp_func/tpenable` | [device] |
| Values | `0` disables (no events at the driver level), `1` enables | same | [device] |

- The rear touch is bound to the E-ink display by `system/usr/idc/ft5x06_ts.idc` (`device.internal = 0`). This is not a kernel interface, but the input device name must stay `ft5x06_ts`. [device]
- On the stock firmware, waking from screen-off with the power key sets the front `tpenable` back to `1`. [device]

## 6. Other

| Interface | Notes | Source |
| --- | --- | --- |
| `/sys/debug_control/mirror/state` | Exists on the stock firmware | [device] |
| Hall sensor | `hall_dev` (`hisense,hall-device`, GPIO 75). Turning the phone over produces no event | [DTB], [device] |

## 7. Checklist for a new kernel

- [ ] fb1 as MDSS fbdev with the DSI1 video panel (384 × 725, 24 bpp, 85 Hz) copied from the DT
- [ ] the ten fb1 attributes in 2.2, same names, mode 0644
- [ ] uevents `EPD_CONNECT=1` and `EPD_CONTROL=%d` on `change@/devices/virtual/graphics/fb1`
- [ ] bitmap commit behaviour (2.6)
- [ ] `/dev/epd_flash` with the same read contract
- [ ] TPS65185 `vcom` (0644) and `thermal` (0444) at `/sys/devices/soc/c176000.i2c/i2c-2/2-0068/`
- [ ] `thermal_zone3` pointing at a matching temperature
- [ ] `leds/epd-backlight`
- [ ] `/sys/ctp/ctp_func/tpenable` and `/sys/ctp1/ctp_func/tpenable`
- [ ] gpio-keys `KEY_LEFT_UP` (616)
- [ ] SELinux labels matching the stock vendor policy
