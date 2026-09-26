# hk-hisense-a6l-lineageOS

Hisense A6L (HLTE730T) 向け LineageOS device tree プロジェクト。

A6L は表面LCD (6.53インチ, 2340×1080) と背面E-Ink Carta HD (5.84インチ, 1440×720) を
持つ二画面スマートフォン。SoCはQualcomm Snapdragon 660 (SDM660)。

## この作業の前提

root化・永続unlock・VoLTE（mineo/KDDI、楽天モバイル）・5GHz WiFiテザリングは、
姉妹リポジトリ [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit)
側で解決済み。このリポジトリはそれを土台として、LineageOS device tree を
ゼロから構築することに専念する。

root/VoLTE/Wi-Fi の手順・パッチ・解析ログはこのリポジトリには含めない。
姉妹リポジトリを参照すること。

## 状態

現在 **device tree 未着手**（雛形のみ）。詳細は [docs/STATUS.md](docs/STATUS.md) を参照。

唯一の公開LineageOS移植の先行事例（XDA投稿者 sniperiusz、2025年）は
「E-ink表示切替のSurfaceFlinger呼び出しとE-inkライト制御」を残して2025年10月に
作業中断しており、ソースは一切公開されていない。本プロジェクトの最大の技術的
目標はこの部分の解決。詳細は [docs/ROADMAP.md](docs/ROADMAP.md)。

## ドキュメント

- [docs/DEVICE.md](docs/DEVICE.md) — ハードウェア仕様、パーティションレイアウト
- [docs/SOURCES.md](docs/SOURCES.md) — 参照リンク集
- [docs/STATUS.md](docs/STATUS.md) — 現状
- [docs/ROADMAP.md](docs/ROADMAP.md) — フェーズ別ロードマップ

## ディレクトリ構成

```
device/hisense/hlte730t/   device tree（未着手、README参照）
vendor/hisense/hlte730t/   proprietary-files.txt / blobs（未着手、README参照）
kernel/hisense/sdm660/     カーネルソース（未着手、README参照）
scripts/                   抽出・再現用スクリプト置き場
```

## 安全に関する重要事項

- IMEI・無線校正値等の個体固有データ（modemst, fsg, persist, QCN, EFS等）は
  **このリポジトリに一切コミットしない**。
- stock firmwareのフルイメージ・大容量blobもコミットしない（`.gitignore`参照）。
