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

## 開発用と持ち歩き用のビルド

`HLTE730T_DEV_ADB`（`device.mk`）で、2 種類を作り分ける。既定は開発用。

| 種類 | 作り方 | adb |
| --- | --- | --- |
| 開発用（既定） | そのまま `m bootimage systemimage` | 最初の起動から有効。鍵の確認なし（`ro.adb.secure=0`）、adbd は root。初期化の直後でもログが取れる |
| 持ち歩き用 | `HLTE730T_DEV_ADB=false m bootimage systemimage` | LineageOS の既定どおり。USB デバッグは設定でオンにし、鍵の確認があり、root は「Rooted debugging」でオンにしたときだけ |

**開発用のビルドは、USB をつないだ誰にでも root のシェルを許す。持ち歩く端末には、必ず持ち歩き用を書く。**

- 変数は、`lunch` の前に環境に置いてもよい（`export HLTE730T_DEV_ADB=false`）。ビルドをコンテナの中で行うときは、この変数をコンテナの中へ渡す。
- 切り替えても、変わるのは system の `prop.default` と、`init.hlte730t.dev-adb.rc` の有無だけ。boot と vendor は共通。
- 確かめ方：`get_build_var WITH_ADB_INSECURE` が、開発用なら `true`、持ち歩き用なら空。書き込んだあとは、`getprop ro.adb.secure` が開発用なら `0`、持ち歩き用なら `1`。
- 出来上がりの名前の付け方の例：開発用は `<日付>-userdebug-<番号>`、持ち歩き用は `<日付>-userdebug-<番号>-carry`。同じ番号どうしは、adb の設定以外は同じ中身にする。

## 書き込み

`boot.img`、`system.img`、`vendor/hisense/hlte730t/prebuilt/vendor.img` を書く。署名していないので、vbmeta は純正のものを検証を切って書く。

```bash
fastboot --disable-verity --disable-verification flash vbmeta vbmeta_live_dump.img
```
