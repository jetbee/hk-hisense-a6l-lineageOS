# device/hisense/hlte730t

Hisense A6L（HLTE730T）の LineageOS 18.1 デバイスツリー。

## 今の構成（第 1 段階）

- **system**：LineageOS 18.1 をビルドする。
- **vendor**：純正の vendor パーティションを元に、次の 3 か所だけを直したイメージを使う（`BOARD_PREBUILT_VENDORIMAGE`）。直す内容は `stage1-vendor/` にあり、`scripts/make-stage1-vendor.sh` が root なしで作る。
  - `/etc/fstab.qcom`：userdata を `forceencrypt=footer` から `encryptable=footer` にし、`crashcheck` を外す（18.1 では FDE の準備に失敗し、/data が読み取り専用になるため）。
  - `/etc/selinux/vendor_file_contexts`：`/dev/epd_flash` を `graphics_device` にする（純正ではこのラベルが Hisense の system 側のポリシーにあり、18.1 にはない）。
  - `/etc/selinux/vendor_sepolicy.cil`：init が `sysfs_graphics`（fb1/epd_connect）に書くこと、HWC が system_prop と default_prop を読むことを許す。
- **カーネル・dtbo**：純正の boot.img から取り出したものをそのまま使う（4.4.153、Image.gz-dtb）。
- **表示**：CAF の HAL はビルドせず、純正のブロブを使う。E-ink の描画（純正の HWC の E-ink の外部ディスプレイと `libtcon_eink`）は純正の hwcomposer.sdm660.so にしかないため。
- **E-ink の自動接続**：`/system/etc/init/init.hlte730t.epd-connect.rc` が、起動完了後に `fb1/epd_connect` に 1 を書く。

ブロブから vendor を組み立てる第 2 段階は、`TARGET_HLTE730T_PREBUILT_VENDOR=false` で切り替える（まだ未完成）。

## ビルドの手順

前提：LineageOS 18.1 のソースがあり、このディレクトリが `device/hisense/hlte730t` にあること。実機から吸い出した `boot_live_dump.img`、`dtbo_live_dump.img`、`vendor_live_dump.img` を 1 つのフォルダに置いておく。

1. カーネル、dtbo、第 1 段階の vendor を用意する（`vendor/hisense/hlte730t/prebuilt/` に置かれる。git には入れない）。

   ```bash
   <このリポジトリ>/scripts/extract-prebuilts.sh <イメージのフォルダ> <LineageOS のソースの場所>
   ```

2. ブロブを取り込む（第 2 段階用。第 1 段階のビルドには不要）。

   ```bash
   ANDROID_BUILD_TOP=$PWD ./device/hisense/hlte730t/extract-files.sh <vendor をマウントした場所の親>
   ```

3. ビルドする。ビルド機によって種類が違う。

   | ビルド機 | コマンド | 理由 |
   | --- | --- | --- |
   | ネイティブの x86_64 Linux | `breakfast hlte730t userdebug` → `m bootimage systemimage` | そのままでよい |
   | Apple Silicon の OrbStack（Rosetta） | `breakfast hlte730t eng` → `m bootimage systemimage` | Rosetta の上では dex2oat が落ちるため、事前コンパイルを切る。Android 11 は、それを eng でしか許さない |

   Rosetta の上かどうかは `BoardConfig.mk` が自動で見分け、事前コンパイルを切る。Rosetta の上で eng 以外を選ぶと、ビルドの最初にエラーで止まる。

## 書き込み

`boot.img`、`system.img`、`vendor/hisense/hlte730t/prebuilt/vendor.img` を書く。署名していないので、vbmeta は純正のものを検証を切って書く。

```bash
fastboot --disable-verity --disable-verification flash vbmeta vbmeta_live_dump.img
```
