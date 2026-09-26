# 現状

更新日: 2026-09-26

## 前提条件（姉妹リポジトリで解決済み、本リポジトリの対象外）

- root化・永続unlock: 完了
- VoLTE (mineo/KDDI、楽天モバイル): 完了
- 5GHz WiFiホットスポット: 完了

詳細: [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit)

## 本リポジトリ (LineageOS device tree) の状態

**Phase 0 完了、Phase 1 方針決定済み。**

- ターゲット: **LineageOS 18.1 (Android 11)**、stockカーネル（4.4.153）のまま（2026-09-26決定）。
  19.1/20（BPF対応の独自カーネル）はその後に検討する。
- ビルドホスト: **M1 Max Mac の OrbStack x86_64 Ubuntu（Rosetta）**（2026-09-26決定）。
  実機作業（adb/fastboot/EDL/QPST）は従来どおり Surface。詳細は [BUILD_ENV.md](BUILD_ENV.md)

- [ ] Phase 1: Linuxビルド環境の準備（ホスト決定済み、環境構築は未着手）
- [ ] Phase 2: stock system/vendorからのproprietary-files抽出（必要なイメージは吸い出し済み）
- [ ] Phase 3: カーネルソースの確保
- [ ] Phase 4: 基本ブリングアップ（LCD表示、adb到達）
- [ ] Phase 5: E-ink統合（表示切替、リフレッシュモード、フロントライト）
- [ ] Phase 6: 仕上げ（Wi-Fi/カメラ/センサー個別検証）

詳細は [ROADMAP.md](ROADMAP.md) を参照。

## 使える手持ちの資材（別PC/フォルダに保管、このリポジトリには非コミット）

- `boot_live_dump.img`, `vbmeta_live_dump.img`, `system_live_dump.img` (rootedだが
  未改造、6GB), `modem_live_dump.img` — `C:\Users\whiterabbit\edl-tool\extracted\`
- `vendor_live_dump.img`（1,153,433,600 B、sha256 `ed51fc66…c24b861`）、
  `dtbo_live_dump.img`（8 MiB、sha256 `e2b375b9…be10b95d`）— 同上。2026-09-26に実機
  （L1632.6.01.04）から root adb の `dd` で吸い出し、実機側とハッシュ一致を確認済み
- stock firmware TFパッケージ3種（HLTE730T向け）— OneDrive `02_firmware/`
- jadx CLI, baksmali/smali 2.5.2, boot classpath一式, pyfatfs, QCSuper など
  解析ツール一式（VoLTE調査で整備済み、パスは姉妹リポジトリのHANDOFFメモ参照）
