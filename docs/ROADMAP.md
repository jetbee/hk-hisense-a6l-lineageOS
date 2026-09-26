# ロードマップ

## Phase 0 — リポジトリ雛形とドキュメント化（完了）

- ディレクトリ構成の作成
- `docs/DEVICE.md` に実機確認済みのGPTパーティション表・ビルドプロパティを記録
- `docs/SOURCES.md` に外部参照リンクを整理
- `docs/STATUS.md` に現状を記録
- `.gitignore` でblob/秘匿データの誤コミットを防止

## Phase 1 — ビルド環境

ターゲットは **LineageOS 18.1 (Android 11)**。ビルドには x86_64 Linuxホストが必須
（ARM64ホスト不可）。詳細は [BUILD_ENV.md](BUILD_ENV.md)。

- ビルドホスト: M1 Max Mac の OrbStack x86_64 Ubuntu（Rosetta）
- 完了条件: 公式18.1対応のSDM660系端末（例: X00TD）で `brunch` が通ること

## Phase 2 — stock stateの解析とproprietary-files抽出

- `system_live_dump.img` またはstock TFパッケージから system/vendor partition
  imageを取り出し、mount
  - vendor / dtbo は2026-09-26に実機から吸い出し済み（[STATUS.md](STATUS.md)参照）。
    手持ちのTFパッケージは2019〜2020年版で、実機（2021年ビルド）と版が合わないため使わない
  - extract-utilsはLineageOSソースツリー内のツールなので、抽出作業はビルドホスト上で行う
- LineageOS `extract-utils` で `proprietary-files.txt` の初期版を生成
- `aospdtgen` 等でboot.img/dtboからBoardConfig.mkの初期値を機械生成し、
  実測GPT値（system=6,442,450,944B, vendor=1,153,433,600B等、
  [docs/DEVICE.md](DEVICE.md)参照）と突き合わせ

## Phase 3 — カーネルソース確保

- Hisenseの GPL/OSS公開窓口を確認（SDM660はLinux kernel 4.4系）
- 公式ソースが得られない場合、boot.img/dtboからのDTB逆解析＋近縁公開SDM660
  カーネル（他社SDM660機のLineageOSカーネル）を出発点にし、差分をHisense DTS
  相当に合わせる

## Phase 4 — 基本ブリングアップ

- 表LCDパネルの表示、adb接続、基本I/Oを最優先
- 姉妹リポジトリのVoLTE解析で確立済みの知見（`oem_sw.txt`、MCFG、
  ModemTestMode内部構造）をLineageOSのRIL設定に反映

## Phase 5 — E-ink統合（本プロジェクト最大の技術的目標）

唯一の公開先行事例（XDA投稿者 sniperiusz）が2025年10月に中断した箇所。
ソースは非公開のため、ゼロから解析する。

- `system_live_dump.img` 上のE-ink関連HAL/サービス/init.rc/sysfsノードを
  jadx/baksmaliで解析（姉妹リポジトリのVoLTE解析で確立済みの
  baksmali deodex → smali編集 → jadx逆コンパイルの手法をそのまま応用）
- SurfaceFlinger二画面切替、E-inkリフレッシュモード、フロントライト制御を
  LineageOS側に実装

## Phase 6 — 仕上げ

- 5GHz Wi-Fi、カメラ、センサー等の個別検証
  （stockでの動作実績はあるが、LineageOSでの動作は別途要確認）
