<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ビルドの覚え書き（引き継ぎ用）

2026-09-26〜27 に、Apple Silicon の Mac（OrbStack の x86_64 Ubuntu 22.04、Rosetta）で LineageOS 18.1 を初めてビルドしたときに分かったことと、その後の覚え書き。以降のメインのビルド機は x86_64 の Linux の PC（AlmaLinux 9 の上のコンテナ）。手順そのものは [device/hisense/hlte730t/README.md](../device/hisense/hlte730t/README.md) を参照。

## 今の到達点

- 第 1 段階（LineageOS 18.1 の system ＋ 直した純正の vendor ＋ 純正のカーネル）で起動する。
- 純正の HWC が 18.1 の SurfaceFlinger で動き、E-ink が Display 1（720x1440）としてつながる。起動後に自動で接続し、パネル固有の波形で描画する（実機で確認済み）。
- Mac の Rosetta の上では eng でビルドした（下記）。ネイティブの x86_64 では userdebug。

## ソースとディレクトリの置き方

- `repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --git-lfs --depth=1`、`repo sync -c --no-tags --no-clone-bundle -j8`。ソースは約 79GB、同期は約 40 分だった。
- このリポジトリの `device/hisense/hlte730t` を、ソースの `device/hisense/hlte730t` に置く。**シンボリックリンクは使えない**：ビルドは `AndroidProducts.mk` を探すときにリンクをたどらず、「product spec がない」と止まる。Mac では bind mount（`/etc/fstab` に書いて常設）にした。コピーするか、ソースの中にこのリポジトリを直接置くのが簡単。
- `extract-files.sh` と `setup-makefiles.sh` は `ANDROID_BUILD_TOP` があればそれをソースの場所として使う（相対パスだと、bind mount やリンクの先から見て外れるため）。
- `vendor/hisense/hlte730t/` は git に入れない（ブロブとイメージ）。
  - `prebuilt/`（カーネル、dtbo、第 1 段階の vendor.img）：`scripts/extract-prebuilts.sh <イメージのフォルダ> <ソース>` で作る
  - `proprietary/`（3,451 ファイル、758MB）：純正の vendor を読み取り専用でマウントして `extract-files.sh <マウント先の親>` で取り込む（第 2 段階用。第 1 段階では使わない）

## 必要なパッケージで、つまずいたもの

- **libncurses5**：renderscript 用の古い clang（`prebuilts/clang/host/linux-x86/clang-3289846`）が `libncurses.so.5` を要る。Ubuntu 22.04 には標準で入っていない。入れないと、ビルドの数分後に `libclcore.bc` で止まる。AlmaLinux 9 では `ncurses-compat-libs` に当たる。
- ほかは LineageOS の wiki の Ubuntu 向けの一覧どおり。

## Rosetta（Apple Silicon の OrbStack）での事前コンパイルの失敗

- `dex2oatd64` が、32 ビット ARM 用のブートイメージを作るところで落ちる（`dchecked_integral_cast failed` や `Check failed: ref <= 0xFFFFFFFFU`）。ブートイメージをメモリの下位 4GB に置く前提が、Rosetta の上では満たされないため。4 時間ビルドした 81% の地点で止まった。
- 環境変数の `WITH_DEXPREOPT=false` は効かない（`build/make/core/board_config.mk` が Linux では true に上書きする）。`BoardConfig.mk` に書く必要がある。
- Android 11 は、userdebug と user で事前コンパイルを切ることを許さない（`DEXPREOPT must be enabled for user and userdebug builds`）。そのため Mac では eng にした。端末では初回起動が遅い。
- `BoardConfig.mk` は、`/proc/sys/fs/binfmt_misc/rosetta` があるとき（Rosetta の上）だけ事前コンパイルを切り、eng 以外なら最初にエラーで止める。**`$(wildcard /proc/...)` は、ビルドの中の kati からは空になって効かなかったので、`$(shell test -e ...)` を使っている。**
- ネイティブの x86_64 では、この判定に当たらないので、userdebug と事前コンパイルがそのまま使える（その後、確かめた）。

## 純正の vendor を直すやり方

- 純正の vendor は ext4 で `shared_blocks` がないので、そのまま書き換えられる。末尾に AVB の検証データがあるが、vbmeta で検証を切っているので、中身を変えても起動は止まらない。
- `scripts/make-stage1-vendor.sh` は root なしで `debugfs` を使い、ファイルを差し替えて、権限・所有者・日時・`security.selinux` のラベルを純正から写す。直す内容は `device/hisense/hlte730t/stage1-vendor/` にある。
- **debugfs は 1.46 以上が要る。** Ubuntu 20.04 の debugfs 1.45.5（ビルド用のコンテナ）では、`write` の書き込み先のフルパスがそのままファイル名になり、ルートの直下に `/etc/fstab.qcom` という名前のファイルができて、イメージが壊れる（e2fsck が「illegal characters」を出す）。そのため、コンテナではなくホスト（AlmaLinux 9、1.46.5）で実行している。スクリプトは、版が足りないと最初に止まる。
- 直した理由
  - `fstab.qcom`：純正は userdata が `forceencrypt=footer`（と Hisense 独自の `crashcheck`）。18.1 では FDE の準備が失敗し（`error_not_encrypted`）、/data が読み取り専用のまま zygote まで進まなかった。
  - `/dev/epd_flash`：純正ではラベル `epd_flash_device` が Hisense の **system 側**のポリシー（と 28.0 の mapping）にあり、18.1 にはない。そのため vendor の許可のルールは中身のない属性に向いていて効かず、HWC が波形を読めずに既定の波形になっていた。今は `graphics_device` にしている。純正と同じ定義を system 側で持つ形は、EpdService を作るときにまとめて行う予定。
  - init から `fb1/epd_connect` に書く：18.1 の基本ポリシーは init が `sysfs` に書くのを禁止している（neverallow）。epd_* は純正の vendor で `sysfs_graphics` のラベルが付いているので、vendor のポリシーで init に `sysfs_graphics` への書き込みを許した。
- system のポリシーと純正の vendor のポリシーの組み合わせは、起動のたびに init が cil から組み立て直す（precompiled のハッシュが一致しないため）。vendor の cil を直したら、`secilc -m -M true -G -N -c 30 <plat_sepolicy.cil> <mapping/28.0.cil> <plat_pub_versioned.cil> <vendor_sepolicy.cil>` で、組み立てられるか確かめてから書き込むとよい。vendor の cil では、platform の型は `init_28_0` のように版つきの名前で書く。

## 書き込み（実機担当向け）

- `boot.img`、`system.img`（sparse）、`vendor.img`。vbmeta は純正を `--disable-verity --disable-verification` で書く。最初は `fastboot -w` をした。
