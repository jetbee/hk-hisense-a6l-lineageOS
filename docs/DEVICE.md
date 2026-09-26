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

- SDM660はLinux kernel 4.4系が一般的（Qualcomm社内ブランチベース）。
- Hisense公式のGPLソース公開有無は未確認（Phase 3で調査）。
- `boot` パーティションは64 MiB（`ANDROID!`ヘッダー確認済み）。

## stockカーネル（`boot_live_dump.img` から確認、2026-09-26）

- `Linux version 4.4.153-perf ... #1 SMP PREEMPT Wed Apr 7 18:34:08 CST 2021`
  （gcc 4.9.x。boot header v1、Image.gz＋DTB 2個を連結、ramdisk_size=0）
- IKCONFIG埋め込みあり（5,420行）。主な値:
  - `# CONFIG_BPF_SYSCALL is not set`、`CONFIG_NETFILTER_XT_MATCH_QTAGUID=y`
    → Android 11まではqtaguidで動くが、Android 12以降はeBPFを要求される可能性が高い
  - `CONFIG_FB_HS_MDSS_EPD_PANEL=y`（Hisense独自のMDSS fbdev E-inkパネルドライバ）
  - `CONFIG_HISENSE_PRODUCT_NAME="hlte730t"`、`CONFIG_HISENSE_PRODUCT_PLATFORM="sdm660_overlay"`
  - その他 `CONFIG_HISENSE_*` / `CONFIG_HS_*` 多数（センサー: TMD3702, STK3X3X, A96T346 など）
- Hisense公式のカーネルソースは未公開（GPL開示を依頼予定）

## E-ink / 二画面まわり（stock実装の構造、2026-09-26解析）

stockは5層構造。LineageOSに無いのは②〜④。

| 層 | 実体 |
|---|---|
| ① アプリ | `app/Eink_Settings`（`com.hmct.einksettings`、sharedUserId=system）、`priv-app/EInkLauncher`、`priv-app/HmctCoreService`（system uid）、`Eink_Clock`、`EInk_*` プラグイン群 |
| ② framework API（Hisense追加） | `com.hmct.epd.EpdManager` / `IEpdManager`（43メソッド: `setDisplayType`, `setDualScreenEnabled`, `setEpdDisplayMode`, `forceClear`, `adjustEinkEffect`, `addViewOnExternal`, `addAppMode` 等）/ `IDirectionDetect` |
| ③ system_server（Hisense追加） | `com.android.server.EpdManagerService`、`policy/HmctPhoneWindowManager`、`EInkToast`、`DisplayManagerInternal.setDisplayType` |
| ④ ネイティブ（Hisense追加） | `SurfaceControl.connectEpdDisplay` / `setDisplayType` / `setEpdMode` / `setBitmapToExternal` → SurfaceFlinger改造 |
| ⑤ カーネル | `/sys/class/graphics/fb1/epd_{contrast,white_threshold,black_threshold}`、`/sys/ctp1/ctp_func/tpenable`（背面タッチ）、`/sys/debug_control/mirror/state` |

関連プロパティ: `persist.sys.epd.{contrast,white,black}`、`sys.sysctl.display_type`、`sys.sysctl.force_display_mode`、`sys.anim.display_mode`、`ro.hmct.panel.epd.support`

移植の考え方:
- 18.1をstockカーネルで動かす場合、⑤はそのまま使える。②③の互換層（APIの形は判明済み）を
  実装すれば、stockのE-inkアプリ群を載せられる可能性がある（system uidのアプリは自前の
  プラットフォーム鍵で再署名）。
- ④は (a) stock SurfaceFlingerのEPD部分を解析してLineageOSのSurfaceFlingerへ移植するか、
  (b) SurfaceFlingerに手を入れず、仮想ディスプレイの内容を常駐デーモンが `fb1` へ転送する方式
  （PaddleStroke氏の `a6l_epdd` に近い考え方）で代替する。
- stockアプリはHisenseの著作物のため、公開リポジトリには含めず、proprietary blobと同様に
  ビルド時に実機から抽出する。

