<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# E-ink display pipeline

Licence: CC BY 4.0

> **要約（日本語）**：Hisense A6L の純正ファームウェアで、裏の E-ink に画面が出るまでの流れ。画面の合成を受け持つ HWC（`hwcomposer.sdm660.so`）と、波形を計算するソフトウェア TCON（`libtcon_eink.so`）の分担、外から見えるふるまい、表示モード、bitmap モード、温度と VCOM をまとめた。Android 16 で、公開の display HAL（CAF の sdm）に E-ink の処理を足して作り直すときの設計図の土台にする。外から見える約束ごとだけを書き、純正の部品の内部の作りは書いていない。

This document describes how the stock Hisense A6L (hlte730t, SDM660) firmware gets an image onto the rear E-ink panel. It is meant as a starting point for re-implementing E-ink support on top of the open display HAL (CAF `sdm`) for a newer Android release.

Only externally visible behaviour and contracts are described: kernel interfaces, files, properties, log strings, and the exported API of a shared library. The internal structure of the stock HWC is not described.

See also: [eink-kernel-interface.md](eink-kernel-interface.md) for the kernel interfaces in detail.

## Source tags

| Tag | Meaning |
| --- | --- |
| **[device]** | Read or exercised on a device running the stock firmware or the LineageOS 18.1 port |
| **[DTB]** | Value from the device tree blob appended to the stock `boot.img` |
| **[dynsym]** | Exported or imported symbol in a shared library's dynamic symbol table, and `DT_NEEDED` entries |
| **[str]** | String found in a stock binary (log messages, paths, property names) |
| **[guess]** | Inference from the above; not verified |

## 1. Division of work

```
apps ── SurfaceFlinger ─┬─ front (LCD): HWC primary display (fb0, DSI0)
                        └─ rear (E-ink): HWC external display
                               ├─ receives the composed image (720 × 1440)
                               ├─ converts it with libtcon_eink.so (software TCON)
                               └─ writes the result to fb1 (DSI1, 384 × 725, 24 bpp, 85 Hz)
                                     └─ panel-side timing controller and TPS65185 drive the E-ink
Control: fb1 sysfs (front/rear state, display mode, ghost clearing, bitmap)
```

| Component | Role | Source |
| --- | --- | --- |
| SurfaceFlinger and libgui | Compose the E-ink as an external display. The stock libgui exports `SurfaceComposerClient::connectEpdDisplay`, `setDisplayType`, `setEpdMode`, `commitBitmap` and `forceClearGhosting` (stock framework API, not present in the 18.1 port) | [dynsym], [device] |
| HWC (`hwcomposer.sdm660.so`) | Drives the E-ink as an external display: opens fb1, receives composed frames, converts them with libtcon, writes them to fb1, handles temperature, VCOM and the waveform flash | [dynsym], [str] |
| libtcon (`libtcon_eink.so`) | Software timing controller: waveform tables, mode decisions, frame generation, contrast, VCOM, temperature. Not specific to the A6L: it still contains MediaTek paths (`/sys/devices/bus.2/11008000.I2C1/i2c-1/1-0048/{vcom,temperature}`), so it appears to be shared with other vendors' devices | [dynsym], [str] |
| Kernel (fb1, `epd_spi`, TPS65185) | fbdev panel, sysfs, uevents, waveform flash, power IC | see eink-kernel-interface.md |

**fb1 most likely carries data re-arranged for the timing controller, not the picture itself**, because its size (384 × 725) differs from the visible E-ink resolution (720 × 1440). [DTB], [device], [guess]

## 2. libtcon interface

### 2.1 Functions the HWC links against

The HWC lists `libtcon_eink.so` in `DT_NEEDED`. Only three libtcon functions appear as undefined symbols in the HWC: [dynsym]

| Function | Related log string in the HWC | Source |
| --- | --- | --- |
| `Init_Eink_SWTcon` | `epd Init_Eink_SWTcon error` on failure | [dynsym], [str] |
| `ReportEinkSWTconLibVersion` | `Tcon version:%d.%d,UseDefaultFlg=%d` | [dynsym], [str] |
| `SetEinkContrast` | — | [dynsym] |

libtcon exports plain C symbols, so argument types cannot be recovered from the ELF.

### 2.2 All exported functions (46)

> Names from the shared library's exported symbol table. This gives no information about the implementation. How the stock HWC uses the functions it does not link directly is not visible from outside.

Grouped by name: [dynsym]

| Group | Functions |
| --- | --- |
| Init and teardown | `Init_Eink_SWTcon`, `Release_Eink_SWTcon`, `Reset_SWTcon_Database`, `Reset_Panel`, `ReportEinkSWTconLibVersion`, `Request_ProcessBuf_Size`, `Read_Config_FILE` |
| Waveform tables | `Decode_WBF_Header`, `Generation_WF_Table`, `Generation_WF_Table_32bits`, `Generation_WF_Table_32bits_Padding`, `Generation_WF_Table_32bits_REGAL`, `Generation_WF_Table_32bits_REGAL_NonFlash`, `Generation_WF_Table_32bits_flash`, `Generation_WF_Table_NonFlash`, `Generation_BinWF_Table`, `generate_wf`, `GetTargetWF`, `Init_A2_LookUP_Table`, `ChangeGLD16Count` |
| Waveform flash | `Get_Flash_Data`, `Set_Flash_Data` |
| Image update | `Update_Display_Image`, `Update_Display_Image_Lib`, `Generation_MixFrame_Y4`, `Generation_MixFrame_Y8_REGAL`, `Generation_MixFrame_Y8_REGAL_ModeChange_MixFrame`, `Generation_MixFrame_Y8_REGAL_ResetFrame`, `Generation_ModeChange_MixFrame`, `Generation_ModeChange_ResetFrame` |
| Display mode | `ModeDecision_MirrorMode`, `ModeDecision_MirrorMode_Lib`, `ModeDecision_ExtenationMode`, `ModeChangeRefresh`, `ModeChangeRefreshA2BoundTable`, `Set_OneMode_Refresh`, `Add_OneMode_Count`, `Reset_ModeCount`, `GetRefreshFlg` |
| Image quality | `SetEinkContrast`, `SetImageContrast` |
| Temperature and VCOM | `Read_Temperture`, `Set_VCOM` |
| Time | `GetCurTime`, `GetRealTime`, `GetARealTime` |

- Dependencies: only `libcutils`, `liblog`, `libc++`, `libc`, `libm`, `libdl`. Nothing ties it strongly to a particular Android release. [dynsym]
- Property read: `sys.sysctl.GC_New_Refresh`. [str]
- The names suggest REGAL, A2 and GL16 waveform modes and Y4/Y8 grey levels. [guess]

## 3. Observable HWC behaviour

| Behaviour | Source |
| --- | --- |
| On the uevent `EPD_CONNECT=1` (fb1), the E-ink appears to Android as an external display (displayId 1, 720 × 1440) | [str], [device] |
| fb1 is opened as `/dev/graphics/fb1`, falling back to `/dev/fb1` | [str] |
| `/dev/epd_flash` is read at start-up (log strings `ReadEpdFlash open error`, `ReadEpdFlash read error` on failure) | [str] |
| `/sys/devices/virtual/graphics/fb1/epd_info` is written (log string `Failed to write into epd info node` on failure) | [str] |
| The TPS65185 `vcom` node is written (log string `Failed to write into epd vcom node` on failure) | [str] |
| The libtcon version is logged as `Tcon version:%d.%d,UseDefaultFlg=%d` | [str] |
| Mode names appear in the log: `normal mode`, `idle mode`, `safe mode`, `unknow mode`, `entry safe mode` / `exit safe mode` | [str] |
| With no image for a while it closes the E-ink (log string `wait frame timeout close epd`) | [str] |
| `epd_display_mode` and `epd_force_clear` changes take effect immediately | [device] |

## 4. Display modes and waveforms

| sysfs | Values | Meaning | Source |
| --- | --- | --- | --- |
| `epd_display_mode` | `0`, `1`, `2`, `3`, `6`, `8` tried | Waveform selection. `1` and `2` flash a lot; `8` is the most usable for normal Android use. Frames in 20 s: 0:39, 1:67, 2:34, 3:34, 6:84, 8:74 | [str], [device] |
| `epd_force_clear` | write to request | Full refresh to clear ghosting | [str], [device] |
| `epd_contrast`, `epd_black_threshold`, `epd_white_threshold` | integers | Image quality | [device] |

The mapping between these values and libtcon's waveform modes (REGAL, A2, GL16 and so on) has not been verified.

## 5. Front/rear state (`epd_display_type`)

| Value | Name in the stock framework (`com.hmct.epd.EpdManager`) | Meaning |
| --- | --- | --- |
| `0` | `DISPLAY_MODE_PRIMARY_ONLY` | Front (LCD) only |
| `1` | `DISPLAY_MODE_PRIMARY_WITH_PRESENTATION` | Front plus independent rear content (clock, widgets) |
| `2` | `DISPLAY_MODE_EXTERNAL_MIRROR` | Rear mirrors front |
| `4` | `DISPLAY_MODE_EXTERNAL_EPAPER` | Rear only; LCD off |
| `-1` | `DISPLAY_MODE_SCREEN_OFF` | Both off |

Writing this value on a running system had no visible effect at the time. [device]

## 6. Bitmap mode

| Item | Value | Source |
| --- | --- | --- |
| File | `/kdebuginfo/edpd/bitmap.raw` | [str] |
| Format | 720 × 1440, RGB565 little-endian, no header, 2,073,600 bytes | [device] |
| Commit | Write `1` to `/sys/class/graphics/fb1/epd_commit_bitmap` | [device] |
| Conditions | Shown only after the E-ink has been blanked by screen-off. While the LCD is in use, only after display 1 has been powered off through SurfaceFlinger. Not accepted in normal mode (log string `epd is normal mode,can not commit bitmap`) | [device], [str] |
| Use | The LineageOS 18.1 port shows its status screens (sleep and "LCD in use") this way; see `docs/epd-service.md` in a6l-eink | [device] |

## 7. Temperature and VCOM

| Item | Location | Source |
| --- | --- | --- |
| Panel temperature | `/sys/devices/soc/c176000.i2c/i2c-2/2-0068/thermal` (TPS65185); `31` on the device | [str], [device] |
| Second temperature | `/sys/class/thermal/thermal_zone3/temp` | [str] |
| VCOM | Written to `/sys/devices/soc/c176000.i2c/i2c-2/2-0068/vcom`. The value matches the one in `epd_info` (2520 on the device) | [str], [device] |

Temperature most likely selects the waveform table, as is usual for E-ink panels. [guess]

## 8. Debug files

| Path | Notes | Source |
| --- | --- | --- |
| `/data/vendor/display/epd_image_%d.raw` | Buffer dumps | [str] |
| `/data/vendor/display/frame_dump_external` | External display frame dumps | [str] |

## 9. Re-implementation options for a newer Android

### 9.1 Options

| Option | Description | Pros | Concerns |
| --- | --- | --- | --- |
| A: keep the stock HWC blob | Load the Android 9 `hwcomposer.sdm660.so` on the new release with shims | No E-ink code to write | HIDL composer, VNDK 28 libraries and the whole `libsdmcore` dependency chain; may not be loadable at all |
| B: add E-ink to the open CAF `sdm` HAL | Write a new external-display path in the open HAL and use only the stock libtcon blob | libtcon depends only on libc-level libraries, so it should load on a new release | How libtcon's functions are meant to be called is not visible from outside (section 9.3) |
| C: draw outside the HWC | A separate daemon takes a virtual display's content, converts it with libtcon and writes fb1 | No HWC changes | More latency; power and mode handling must be owned by the daemon |

### 9.2 Behaviour a new implementation must provide (option B)

- Create the external display on `EPD_CONNECT=1` and follow `EPD_CONTROL`
- At start-up: read `/dev/epd_flash`, initialise libtcon, apply temperature and VCOM
- Per frame: convert the composed 720 × 1440 image with libtcon and write it to fb1 (384 × 725, 24 bpp)
- Follow `epd_display_mode`, `epd_force_clear` and `epd_display_type`
- Bitmap mode: on `epd_commit_bitmap`, show `/kdebuginfo/edpd/bitmap.raw` under the conditions in section 6
- Idle handling: rest when no image arrives; close the E-ink after a longer timeout

### 9.3 Open questions

1. How the libtcon functions not linked by the HWC (`Update_Display_Image` and others) are meant to be used
2. Argument types of each function, and the buffer size set by `Request_ProcessBuf_Size`
3. Mapping of `epd_display_mode` values to waveform modes
4. Meaning of each `EPD_CONTROL` value
5. Layout of `/dev/epd_flash`

Items 1 and 2 would be answered by public documentation for the software TCON library (for example an E Ink SWTcon SDK). Without it, options A or C are the realistic paths.
