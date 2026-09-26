# 現状

更新日: 2026-09-26

## 前提条件（姉妹リポジトリで解決済み、本リポジトリの対象外）

- root化・永続unlock: 完了
- VoLTE (mineo/KDDI、楽天モバイル): 完了
- 5GHz WiFiホットスポット: 完了

詳細: [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit)

## 本リポジトリ (LineageOS device tree) の状態

**未着手。** ディレクトリ雛形とドキュメントのみ存在する（Phase 0）。

- [ ] Phase 1: Linuxビルド環境の準備
- [ ] Phase 2: stock system/vendorからのproprietary-files抽出
- [ ] Phase 3: カーネルソースの確保
- [ ] Phase 4: 基本ブリングアップ（LCD表示、adb到達）
- [ ] Phase 5: E-ink統合（表示切替、リフレッシュモード、フロントライト）
- [ ] Phase 6: 仕上げ（Wi-Fi/カメラ/センサー個別検証）

詳細は [ROADMAP.md](ROADMAP.md) を参照。

## 使える手持ちの資材（別PC/フォルダに保管、このリポジトリには非コミット）

- `boot_live_dump.img`, `vbmeta_live_dump.img`, `system_live_dump.img` (rootedだが
  未改造、6GB), `modem_live_dump.img` — `C:\Users\whiterabbit\edl-tool\extracted\`
- stock firmware TFパッケージ3種（HLTE730T向け）— OneDrive `02_firmware/`
- jadx CLI, baksmali/smali 2.5.2, boot classpath一式, pyfatfs, QCSuper など
  解析ツール一式（VoLTE調査で整備済み、パスは姉妹リポジトリのHANDOFFメモ参照）
