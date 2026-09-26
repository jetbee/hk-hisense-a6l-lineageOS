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

## E-ink / 二画面まわり（未解析）

stockのE-ink切替・リフレッシュモード・フロントライト制御の実装（HAL/サービス/
init.rc/sysfsノード）は未解析。Phase 5で `system_live_dump.img` を対象に
jadx/baksmaliで解析する予定。姉妹リポジトリのVoLTE解析で確立した手法
（baksmali deodex → smali編集 → jadx逆コンパイル）がそのまま応用できる見込み。
