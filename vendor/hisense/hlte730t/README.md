# vendor/hisense/hlte730t

現在空。`proprietary-files.txt` と抽出済みblob（vendorイメージ）をここに置く。

## ここを埋めるために次に必要な入力

1. stock `system`/`vendor` partition imageのmount
   （`system_live_dump.img` を優先。root化済み・未改造なのでstock blobの
   ソースとして使える。無ければstock TFパッケージから展開）
2. LineageOS `extract-utils` の実行（[../../../docs/SOURCES.md](../../../docs/SOURCES.md)
   参照）

## 注意

- IMEI・無線校正値等の個体固有ファイル（modemst, fsg, persist, QCN, EFS）は
  対象外。`proprietary-files.txt` に含めない。
- blob本体は `.gitignore` により誤コミットされない設定になっているが、
  念のため追加前に個体固有性の有無を確認すること。
