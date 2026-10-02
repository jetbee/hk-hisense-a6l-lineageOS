# Band mode per SIM slot (LTE-only SIMs in Japan)

日本語の要約：A6L のモデムは、日本の LTE だけの SIM（au 系、楽天など）を、その SIM の 2G/3G のバンドを「Cellular 800」（RIL のバンドモード 6）にしないと LTE で登録しないことがあります。純正では「*#*#4636#*#*」から SIM1 にしか設定できませんでした。このデバイスツリーは、AOSP の電話アプリ（TeleService）に小さなパッチを当て、スロットごとに設定できるようにしています（adb の `cmd phone band-mode` と、電話情報の画面）。設定はモデムに保存されます。また、データ通信の SIM でない側の LTE は、スロット 1 だけに許されるようです（下の「既知の制約」）。

## What it is

`RIL_REQUEST_SET_BAND_MODE` sets a SIM's 2G/3G/CDMA band preference in the
modem. On this device the stock firmware's users set "Cellular 800" (band
mode 6) on SIM1 through *Phone info > Select radio band*: it leaves only CDMA
800 in the 2G/3G band preference, which in Japan means no usable 2G/3G, so
the SIM stays on LTE. The LTE band preference is not changed.

AOSP's *Select radio band* only ever changes the default phone (slot 0).

## The patch

`device/hisense/hlte730t/patches/packages_services_Telephony/` (apply with
`device/hisense/hlte730t/patches/apply.sh <source tree>`), against
`packages/services/Telephony` of LineageOS 18.1:

- `cmd phone band-mode SLOT_ID` lists the band modes the modem reports for
  that slot (`RIL_REQUEST_QUERY_AVAILABLE_BAND_MODE`).
- `cmd phone band-mode SLOT_ID MODE` sets the band mode of that slot.
  Only adb (shell or root) may call it; root is not needed.
- *Phone info* (`*#*#4636#*#*`) passes the phone index selected at the top of
  the screen to *Select radio band*; its title shows the index.

Slots count from 0 (0 = SIM1, 1 = SIM2). Band modes are `Phone.BM_*`:
0 automatic, 1 Europe, 2 USA, 3 Japan, 4 Australia, 5 Australia 2,
6 cellular 800, 7 PCS, ...

## Use

```
adb shell cmd phone band-mode 1        # what the modem accepts for SIM2
adb shell cmd phone band-mode 1 6      # SIM2: cellular 800
adb shell cmd phone band-mode 1 0      # back to automatic (all bands)
```

The modem stores the setting per SIM slot (it survives reboots, userdata
wipes and system updates), so it is set once.

## Default network type

`device.mk` sets `ro.telephony.default_network=22,22` as the stock firmware
did (every RAT including LTE). Without it LineageOS 18.1 starts both slots
on "WCDMA preferred" without LTE. It only applies to SIMs without a saved
choice; the user's choice in Settings is kept.

## Verify

- `adb shell cmd phone band-mode 1` prints `slot 1 available: ...`.
- After setting, `adb logcat -b radio -d | grep SET_BAND_MODE` shows the
  request on `[PHONE1]` without an error.
- `adb shell dumpsys telephony.registry` shows both slots `IN_SERVICE` and
  `getprop gsm.network.type` is `LTE,LTE`.

## Known limits

- Observed on the device (2026-10-03): with both slots on cellular 800, both
  SIMs stay on LTE only while the mobile data SIM is in slot 2; with data on
  slot 1, SIM2 goes out of service. Slot 1 keeps LTE when it is not the data
  SIM. This looks fixed to the slot (the modem lets only subscription 0 keep
  LTE as the non-data SIM); practical answer: keep mobile data on slot 2.
  Not yet confirmed further.
- VoLTE (IMS) is not set up, so voice calls do not work on LTE-only SIMs.
