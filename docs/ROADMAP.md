<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ロードマップ

## 済んだこと（LineageOS 18.1）

1. **ビルドの環境**：x86_64 の Linux でビルドする（[BUILD_ENV.md](BUILD_ENV.md)）。
2. **純正の部品の扱い**：`proprietary-files.txt` と `extract-files.sh` で、自分の端末から取り出す形にした。第 1 段階は、純正の vendor を数か所だけ直して使う。
3. **起動**：純正のカーネルと vendor のまま、LineageOS 18.1 の system で起動。
4. **E-ink**：純正の動きを調べて仕様書にまとめ、その仕様書だけを見て、API、サービス、設定のアプリを一から書いた（別のリポジトリ hk-hisense-a6l-eink）。純正の HWC がパネルを描く。
5. **仕上げ**：FBE、時刻、2 枚の SIM の LTE、スロットごとのバンドモード、VoLTE（スロット 1）、5 GHz のテザリング。

## これから

- **18.1 の残り**：光・近接センサー（Hisense 独自のセンサーの種類）、Bluetooth の MAC アドレス、スロット 2 をデータの SIM にしたときの、VoLTE の通話中の切断。
- **新しい Android**：Android 12 以降は eBPF を使うので、純正の 4.4 のカーネルでは動かない。公開されている SDM660 の新しいカーネルに、A6L の部品（タッチ、E-ink のパネルと電源、指紋、センサーなど）を移す必要がある。E-ink は、カーネルのドライバと、パネルを描く部分（今は純正の HWC）を作り直すことになる。
- **カーネルのソース**：Hisense にカーネルのソース（GPL）の開示を求めている。
