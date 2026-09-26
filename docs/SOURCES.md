# 参照リンク集

## このデバイス (Hisense A6L / HLTE730T) 関連

- [XDA root/LineageOSスレッド](https://xdaforums.com/t/hisense-a6l-root.4712804/) —
  投稿者 sniperiusz。2025-02-02 root成功、2025-03-25 LineageOS作業報告
  （リフレッシュレート制御動作、E-ink切替とライト制御が残課題）、
  2025-10-06 作業中断報告。**ソース非公開。**
- [tombaczynski/Hisense-A6L](https://github.com/tombaczynski/Hisense-A6L) —
  公開rootガイド（`rooting.md`）。LineageOS関連情報は無し。
- [jetbee/hk-hisense-a6l-root-volte-toolkit](https://github.com/jetbee/hk-hisense-a6l-root-volte-toolkit) —
  **本プロジェクトの姉妹リポジトリ。** root化・永続unlock・VoLTE（mineo/KDDI、
  楽天モバイル）・5GHz WiFiテザリングの解決済み手順とパッチ。
- [bkerler/edl issue #821](https://github.com/bkerler/edl/issues/821) —
  A6L公式ファームウェア付属のFirehoseローダーがSahara認証で失敗する問題と、
  姉妹機HLTE700T(A6)由来のローダー (`prog_emmc_ufs_firehose_Sdm660_ddr_30060000.elf`)
  が代替として機能する情報。
- [XDA旧A6 rootスレッド](https://xdaforums.com/t/how-to-unlock-or-root-hisense-a6.3919052/)

## 近縁機種（同じHisenseの二画面E-inkシリーズ、参考用。SoCは異なる）

- [denzilferreira/vendor_hisense](https://github.com/denzilferreira/vendor_hisense) —
  Hisense A9 (Snapdragon 662) 向けLineageOS vendorツリー。LineageOS 20 (Android 13)
  でカメラ・GPS・指紋認証が動作する実績あり。E-inkリフレッシュ切替サービス、
  Night Light連携によるwarm backlight、AOD等の実装パターンが参考になる。
  ただしSoCが異なる (SD662 vs SD660) ためコードの直接流用は不可、設計の参考のみ。
- [aimindseye/hisense-a9](https://github.com/aimindseye/hisense-a9) — Hisense A9の
  root/カスタムfastboot情報まとめ。
- [XDA Hisense A9 Root (Snapdragon 662)](https://xdaforums.com/t/hisense-a9-root-snapdragon-662.4495809/) —
  非常に活発なスレッド（100ページ超）。LineageOS移植の進捗が詳細に記録されている。

## 近縁SoC（SDM660プラットフォーム、LineageOS 19.1の公式実例）

- [LineageOS/android_device_asus_X00TD](https://github.com/LineageOS/android_device_asus_X00TD) +
  [android_device_asus_sdm660-common](https://github.com/LineageOS/android_device_asus_sdm660-common) —
  Zenfone Max Pro M1 (SDM636)。**SDM660系で公式に19.1（および20）まで対応した唯一の端末**
  （lavender / jasmine_sprout / wayne / X01BD / platina は18.1止まり）。
  device tree構成の主要な参考、かつビルド環境の検証ターゲット。
- [LineageOS/android_kernel_asus_sdm660](https://github.com/LineageOS/android_kernel_asus_sdm660) —
  上記のカーネル。lineage-19.1ブランチで **Linux 4.4.302**。
- [TheMuppets/proprietary_vendor_asus](https://github.com/TheMuppets/proprietary_vendor_asus) —
  上記のベンダーblob（lineage-19.1ブランチあり）。

## ツール

- [LineageOS extract-utils](https://github.com/LineageOS/android_tools_extract-utils) —
  proprietary-files.txt生成・blob抽出
- [aospdtgen](https://github.com/sebaubuntu-python/aospdtgen) — 実機/イメージから
  BoardConfig.mk等の初期値を生成
- Android Platform Tools, Magisk, QPST — 姉妹リポジトリの `03_tools/` 参照
