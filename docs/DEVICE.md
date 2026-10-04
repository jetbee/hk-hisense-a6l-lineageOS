<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# デバイス仕様

## 基本情報

| 項目 | 値 |
|---|---|
| モデル | Hisense A6L |
| 内部型番 | HLTE730T |
| SoC | Qualcomm Snapdragon 660 (SDM660) |
| 表面ディスプレイ | 6.53インチ LCD, 2340×1080 (395 ppi) |
| 背面ディスプレイ | 5.84インチ E-Ink Carta HD, 1440×720 (287 ppi) |
| RAM | 6 GB |
| ストレージ | 64/128 GB (+microSD 256GBまで) |
| バッテリー | 3,800 mAh, Quick Charge 3.0 |
| 出荷OS | Android 9 |
| ストレージ種別 | eMMC |
| ブートローダー | ロック（root化済み個体は永続unlock済み。姉妹リポジトリ参照） |

出典: [Good e-Reader unboxing記事](https://goodereader.com/blog/smartphones/unboxing-the-hisense-a6l-dual-screen-e-ink-lcd-smartphone)

## 確認済みビルドプロパティ（出荷時 stock、個体固有ではない値）

- `ro.build.version.incremental`: `L1632.6.01.04`
- 設定画面表示: `L1632.6.09.07.00`（プロパティとの相違は未解明）

## GPTパーティションレイアウト（実機EDL読出しで確認済み、A/Bスロットなし）

出典: 実機からのFirehose読出しログ（姉妹リポジトリ管理、`06_logs/edl-firehose/gpt-partitions.txt`）

| # | パーティション | サイズ |
|---:|---|---:|
| 0 | xbl | 3.5 MiB |
| 1 | tz | 4 MiB |
| 5 | fsg | 2 MiB |
| 11 | modem | 110 MiB |
| 12 | dsp | 16 MiB |
| 24 | bluetooth | 1 MiB |
| 26 | vbmeta | 64 KiB |
| 28 | boot | 64 MiB |
| 29 | recovery | 64 MiB |
| 32/33 | modemst1 / modemst2 | 2 MiB each |
| 35 | diag | 1 MiB |
| 39 | metadata | 10 MiB |
| 41 | dtbo | 8 MiB |
| **42** | **system** | **6,442,450,944 B (6 GiB)** |
| **43** | **vendor** | **1,153,433,600 B (~1.07 GiB)** |
| 44 | cache | 256 MiB |
| 45 | persist | 32 MiB |
| 57 | userdata | ~114.7 GB |

要点:
- `system` と `vendor` が分離済み（Project Treble相当のレイアウト）。
- `dtbo` パーティションが存在 → device tree overlayを使うブート構成。
- A/Bスロット (`_a`/`_b`) は存在しない、旧来のシングルスロット構成。
- `recovery` パーティションが独立して存在（A/Bデバイスと異なりrecovery.imgを別途扱う）。

## カーネル

- 純正のカーネルは `Linux version 4.4.153-perf ... #1 SMP PREEMPT Wed Apr 7 18:34:08 CST 2021`（gcc 4.9.x）。boot header v1、Image.gz に DTB を 2 つ連結、ramdisk_size=0。`boot` パーティションは 64 MiB。
- 設定（IKCONFIG）の主な値：
  - `# CONFIG_BPF_SYSCALL is not set`、`CONFIG_NETFILTER_XT_MATCH_QTAGUID=y` → Android 11 までは qtaguid で動くが、Android 12 以降は eBPF が要る。
  - `CONFIG_FB_HS_MDSS_EPD_PANEL=y`：E-ink のパネルは Hisense 独自の MDSS fbdev のドライバ。
  - `CONFIG_HISENSE_PRODUCT_NAME="hlte730t"`、`CONFIG_HISENSE_PRODUCT_PLATFORM="sdm660_overlay"`。ほかに Hisense 独自のセンサーなどの設定（TMD3702、STK3X3X、A96T346 など）。
- Hisense はカーネルのソースを公開していない（GPL にもとづく開示を求めている）。

## E-ink と二画面

純正の E-ink は、次の層でできている。LineageOS にないのは、API とサービスの層。

| 層 | 純正 | この移植 |
|---|---|---|
| アプリ | Hisense の E-ink の設定、ランチャー、時計など | 入れない。代わりに自前の設定のアプリ |
| API | `com.hmct.epd.EpdManager`、`IEpdManager`、`IDirectionDetect`（binder の名前は `epd`） | 互換の API を自前で書いた（hk-hisense-a6l-eink） |
| サービス | system_server の中の E-ink のサービス | 自前のサービスのアプリ（hk-hisense-a6l-eink） |
| 描画 | 純正の HWC（vendor の中）が、E-ink を外部ディスプレイ（display 1）として描く | 純正の HWC をそのまま使う |
| カーネル | `/sys/class/graphics/fb1/epd_*`、`/sys/ctp1/ctp_func/tpenable`（背面のタッチ）など | 純正のカーネルをそのまま使う |

関連するプロパティ：`persist.sys.epd.{contrast,white,black}`、`sys.sysctl.display_type`、`sys.sysctl.force_display_mode`、`sys.anim.display_mode`、`ro.hmct.panel.epd.support`。

E-ink の部品は、純正の動きを外から調べて仕様書にまとめ、その仕様書だけを見て一から書いた。純正のアプリと互換にするため、名前や番号は純正と同じにしてある。外から見た振る舞いは [eink-display-pipeline.md](eink-display-pipeline.md) と [eink-kernel-interface.md](eink-kernel-interface.md) にまとめてある。
