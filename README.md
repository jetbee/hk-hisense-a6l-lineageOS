<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# hk-hisense-a6l-lineageOS

Hisense A6L（HLTE730T）向けの LineageOS 18.1（Android 11）のデバイスツリー。

A6L は、表に LCD（6.53 インチ、1080×2340）、背面に E-ink（Carta、5.84 インチ、720×1440）を持つ二画面のスマートフォン。SoC は Qualcomm Snapdragon 660（SDM660）。

## できること・できないこと

| 機能 | 状態 |
|---|---|
| 起動、LCD、タッチ（表と背面）、指紋、Wi-Fi（5 GHz のテザリングを含む）、音声通話、モバイルデータ | 動く |
| E-ink（背面） | 動く。表示の切り替え、アプリごとの表示モード、スリープ中の画面、E-ink のキー、指ごとのロック解除。E-ink の部品は別のリポジトリ（[下を参照](#e-ink-の部品)） |
| 暗号化 | userdata をファイルベースの暗号化（FBE、eMMC のインライン暗号）にする |
| SIM | 2 枚とも LTE。日本の LTE だけの SIM のための、スロットごとのバンドモード（[docs/telephony-band-mode.md](docs/telephony-band-mode.md)） |
| VoLTE | 物理スロット 1 の SIM だけ（発信、着信、通話中のデータ）。IMS の部品は、このリポジトリには入っていない（各自で用意する。下を参照） |
| ビデオ通話（VT）、スロット 2 の VoLTE | できない |
| 光・近接センサー、Bluetooth の MAC アドレス | まだ不完全（[docs/hardware-notes.md](docs/hardware-notes.md)） |
| 純正の E-ink アプリ（Hisense のランチャーや時計など） | 入れていない。互換の API（`com.hmct.epd`）は自前で用意している |
| GApps | 入れていない。`vendor/gapps`（MindTheGapps）を置けば、ビルドのときに取り込む |

## 構成

- **system**：LineageOS 18.1 をビルドする。
- **vendor**：利用者が自分の端末から読み出した純正の vendor を元に、数か所だけを直したイメージ（第 1 段階）。直す内容は `device/hisense/hlte730t/stage1-vendor/` にあり、`scripts/make-stage1-vendor.sh` が作る。
- **カーネル、dtbo**：利用者が自分の端末の boot から取り出した純正のもの（4.4.153）を使う。Hisense はカーネルのソースを公開していない（[kernel/hisense/sdm660/README.md](kernel/hisense/sdm660/README.md)）。
- **E-ink**：純正の HWC（vendor の中）がパネルを描き、その上の API、サービス、設定の画面は、自前の部品（[下を参照](#e-ink-の部品)）に置き換えている。
- **VoLTE**：IMS のアプリとライブラリは、公式の LineageOS 18.1 の SDM660 機向けのものを `vendor/a6l-ims` に置いたときだけ取り込む。このリポジトリにあるのは、その設定（device.mk と overlay）だけ。

純正のブロブ、イメージ、カーネルは、このリポジトリに入っていない。どれも利用者が自分の端末から取り出して使う。

## 作り方と書き込み方

手順は [device/hisense/hlte730t/README.md](device/hisense/hlte730t/README.md) にまとめてある。あらまし：

1. LineageOS 18.1 のソースを用意し、このリポジトリの `device/hisense/hlte730t` を、ソースの `device/hisense/hlte730t` に置く（シンボリックリンクは使えない）。
2. E-ink の部品を、ソースの `vendor/a6l-eink` に置き、その `epd/patches/apply.sh` で framework にパッチを当てる。
3. `device/hisense/hlte730t/patches/apply.sh` で、AOSP（Telephony）にパッチを当てる。
4. 自分の端末から boot、dtbo、vendor を読み出し（root が要る）、`scripts/extract-prebuilts.sh` でカーネル、dtbo、第 1 段階の vendor を作る。
5. `breakfast hlte730t userdebug` のあと `m bootimage systemimage`。既定は持ち歩き用（adb は LineageOS の既定どおり）。開発用（最初から root の adb）は `HLTE730T_DEV_ADB=true` で作る。
6. fastboot で boot、system、vendor を書き、vbmeta は純正のものを検証を切って書く。

## E-ink の部品

E-ink の API（`com.hmct.epd`）、サービス、設定のアプリ、framework へのパッチは、別のリポジトリ **hk-hisense-a6l-eink** にある。clean-room 方式に倣い、純正の動きの調査と仕様書の作成、仕様書からのソースコードの作成を、別の担当が行った。仕様書は公開しない。設計と開発の記録は、別に内部の書庫に保全してある。純正のアプリと互換にするため、名前や番号（`com.hmct.epd`、binder の名前、AIDL のトランザクション番号、設定のキー）は純正と同じにしてある。

## 既知の問題

- VoLTE は物理スロット 1 の SIM だけ（モデムの IMS がスロット 1 に固定されている）。
- モバイルデータの SIM をスロット 2 にしていると、スロット 1 の VoLTE の通話中にデータを使ったとき、通話が切れることがある。VoLTE を使うなら、データの SIM もスロット 1 にする。
- 再起動のあと、モバイルデータの SIM が別の SIM に戻ることがある。
- 開発用と持ち歩き用を書き替えたあと、USB をつなぎ直さないと adb がつながらないことがある。
- 純正の HWC は、E-ink がつながる前に E-ink の調整値を書くと落ちる。自前のサービスは、つながったあとに書く（[docs/hardware-notes.md](docs/hardware-notes.md)）。

## 文書

- [docs/hardware-notes.md](docs/hardware-notes.md)：ハードウェアと、移植で分かったこと
- [docs/eink-display-pipeline.md](docs/eink-display-pipeline.md)、[docs/eink-kernel-interface.md](docs/eink-kernel-interface.md)：純正の E-ink の表示のしくみ（外から見た振る舞い）
- [docs/telephony-band-mode.md](docs/telephony-band-mode.md)：スロットごとのバンドモード
- [docs/DEVICE.md](docs/DEVICE.md)：端末の仕様、パーティション
- [docs/BUILD-NOTES.md](docs/BUILD-NOTES.md)、[docs/BUILD_ENV.md](docs/BUILD_ENV.md)：ビルドの覚え書き
- [docs/STATUS.md](docs/STATUS.md)、[docs/ROADMAP.md](docs/ROADMAP.md)：今の状態と、この先
- [docs/SOURCES.md](docs/SOURCES.md)：参考にしたもの

root 化と、純正の上での VoLTE などの手順は、姉妹リポジトリ [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit) にある。

## 安全のために

- IMEI や無線の校正値など、端末ごとのデータ（modemst、fsg、persist、QCN、EFS など）は、決してコミットしない。書き込みの前に、自分の端末のバックアップを取る。
- 純正のイメージやブロブもコミットしない（`.gitignore` を参照）。
- 開発用のビルドは、USB をつないだ誰にでも root のシェルを許す。持ち歩く端末には、持ち歩き用を書く。

## ライセンス

- コード（Makefile、スクリプト、rc、sepolicy、設定、パッチなど）：Apache License 2.0（[LICENSE](LICENSE)）。
- 文書（`docs/` と README）：Creative Commons Attribution 4.0 International（CC BY 4.0、[docs/LICENSE.md](docs/LICENSE.md)）。
- 純正のブロブとイメージは Hisense や Qualcomm などのもので、このリポジトリには含まない。
