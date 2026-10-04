<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# 今の状態

更新日：2026-10-04

## LineageOS 18.1（Android 11）

日常で使える版になった。できること・できないことは [README](../README.md) の表を参照。

- 構成：LineageOS 18.1 の system、純正の vendor を数か所だけ直したもの、純正のカーネル（4.4.153）。
- E-ink：純正の HWC がパネルを描き、API、サービス、設定の画面は、自前の部品（hk-hisense-a6l-eink）に置き換えた。
- 暗号化：userdata はファイルベースの暗号化（FBE）。
- 通信：2 枚の SIM で LTE、スロットごとのバンドモード、VoLTE（物理スロット 1 だけ）、5 GHz のテザリング（W52）。
- ビルドは、開発用（最初から root の adb）と持ち歩き用（既定）を作り分ける。

## 経過

| 時期 | できたこと |
|---|---|
| 2026-09-26 | デバイスツリーの最初の形。純正の vendor とカーネルのまま、LineageOS の system で起動 |
| 2026-09-27〜10-01 | E-ink の自動接続、背面のタッチ、keymaster の HMAC の取り決め、5 GHz のテザリング |
| 2026-10-02〜03 | FBE、時刻の引き継ぎ、スロットごとのバンドモード、E-ink の部品を自前のものに置き換え |
| 2026-10-04 | VoLTE（スロット 1）を実機で確認 |

## 前提（このリポジトリの外）

root 化、ブートローダーのアンロック、純正の上での VoLTE などは、姉妹リポジトリ [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit) で扱っている。

## 次

[ROADMAP.md](ROADMAP.md) を参照。
