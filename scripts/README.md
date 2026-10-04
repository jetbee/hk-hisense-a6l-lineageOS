<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# scripts

| スクリプト | すること |
|---|---|
| `extract-prebuilts.sh` | 自分の端末から読み出した boot、dtbo、vendor から、カーネル（Image.gz-dtb）、dtbo、第 1 段階の vendor を作り、`vendor/hisense/hlte730t/prebuilt/` に置く |
| `make-stage1-vendor.sh` | 純正の vendor のイメージを、root なしで（debugfs で）直して、第 1 段階の vendor を作る。直す内容は `device/hisense/hlte730t/stage1-vendor/` |
| `patch-vendor-fstab.sh` | 以前の手順（root でループマウントして直す）。fstab の userdata の行を書き換える。今は `make-stage1-vendor.sh` がまとめて行う |
| `patch-vendor-sepolicy-epd.sh` | 以前の手順（同上）。E-ink のための vendor のポリシーを追記する。今は `make-stage1-vendor.sh` がまとめて行う |
| `gen_proprietary_files.py` | 純正の vendor のファイルの一覧から、`proprietary-files.txt` の下書きを作る |

どのスクリプトも、純正のイメージを含まない。利用者が自分の端末から読み出したイメージを入力にする。
