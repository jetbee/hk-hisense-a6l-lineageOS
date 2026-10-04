<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ビルドの環境

## 要るもの

- **x86_64 の Linux。** LineageOS のソースが取ってくるホスト用の道具（clang、go、bazel、cmake など）は `linux-x86` と `darwin-x86` しかなく、ARM64 の Linux では動かない。AOSP の公式の要件も x86-64（[source.android.com/docs/setup/start/requirements](https://source.android.com/docs/setup/start/requirements)）。
- **メモリ**：32 GB 以上が目安（LineageOS の wiki）。
- **ディスク**：18.1 のソースが約 80 GB、out/ と ccache を合わせて 300 GB ほど。
- 必要なパッケージは LineageOS の wiki の一覧のとおり。Ubuntu 22.04 では、それに加えて `libncurses5` が要る（[BUILD-NOTES.md](BUILD-NOTES.md)）。
- 第 1 段階の vendor を作る `scripts/make-stage1-vendor.sh` には、e2fsprogs 1.46 以上（debugfs）が要る。

## 試したビルドの環境

| 環境 | 結果 |
|---|---|
| x86_64 の Linux の PC（ネイティブ、またはコンテナの中の Ubuntu 20.04） | userdebug で、事前コンパイルもそのままビルドできる。今のメインのビルド環境 |
| Apple Silicon の Mac（OrbStack の x86_64 Ubuntu 22.04、Rosetta） | ビルドできるが、Rosetta の上では dex2oat が落ちるので、事前コンパイルを切った eng だけ。`BoardConfig.mk` が自動で見分ける（[BUILD-NOTES.md](BUILD-NOTES.md)） |

## ソースの取り方

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --git-lfs --depth=1
repo sync -c --no-tags --no-clone-bundle -j8
```

そのあとの手順は [device/hisense/hlte730t/README.md](../device/hisense/hlte730t/README.md) を参照。
