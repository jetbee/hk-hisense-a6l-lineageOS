# ビルド環境

## 方針（2026-09-26決定、同日に 19.1/EC2 案から変更）

| 項目 | 決定 |
|---|---|
| ターゲット | **LineageOS 18.1 (Android 11)**、stockカーネルのまま |
| ビルドホスト | **Apple Silicon の Mac の OrbStack x86_64 Ubuntu（Rosetta）** |
| 実機操作（adb/fastboot/EDL/QPST） | Windows の PC — 従来どおり |

### ホストの選定理由

AOSP/LineageOSのビルドは **x86_64 Linuxホスト必須**。

- LineageOSのmanifest（18.1 / 22.2 / 23.0で確認）が取得するホスト用prebuilt
  （clang, go, bazel, cmake, gcc）は `linux-x86` / `darwin-x86` のみで、`linux-arm64` は存在しない。
  ARM64 Linux（Apple Silicon上のARM VM、DGX Spark等）ではこれらが実行できない。
- AOSP公式要件: [source.android.com/docs/setup/start/requirements](https://source.android.com/docs/setup/start/requirements)
  （x86-64必須、macOSは2021-06以降非サポート）
- Google社員の発言: [android-building (2021-06-09)](https://groups.google.com/g/android-building/c/G01E2O9egKw)

検討した候補:

| ホスト | 評価 |
|---|---|
| 4 コアのファンレスのノート PC（16GB） | 19.1には RAM不足（wiki目安: 18.1で32GB以上）。初回ビルドは一晩以上 |
| Apple Silicon の Mac + OrbStack x86_64 VM（Rosetta） | 可能。ただしnsjail無効化・`WITH_DEXPREOPT=false` が必要な実例あり（[AOSP 14 on M3 Max](https://shumxin.github.io/2024/04/05/build-aosp-in-mackbook-pro-m3-max/)）。未知のRosetta起因エラーのリスク |
| i7 MacBook Pro 32GB（Intel、VM） | 互換性は確実だがVMに割けるRAMが24〜26GBで不足気味 |
| DGX Spark（ARM64）+ FEX-Emu | AOSPビルドの前例なし。x86 TSOメモリ順序のソフト再現が必要で、並列ビルドで不安定化の懸念。実験枠 |
| **EC2 c7i.8xlarge** | x86_64ネイティブ、32 vCPU / 64GB。初回ビルド1回 約$7 |
| **ThinkPad P51**（Ubuntuネイティブ） | x86_64ネイティブ、45W冷却、RAM増設可。取りに行く手間のみ |

## OrbStack でのビルド手順

（Mac 側で構築したら、ここに追記する。Rosetta 起因の既知の回避策として、nsjail の無効化と
`WITH_DEXPREOPT=false` が必要になる可能性がある。上の選定理由の表を参照）

## EC2でのビルド手順（当初案、代替として残す）

以下は 19.1 前提で書いた当初の手順。使う場合は `lineage-19.1` を `lineage-18.1` に読み替えること。

### 0. 事前準備（初回のみ）

1. **vCPUクォータ確認**: Service Quotas → EC2 →
   「Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances」が **32以上** あること。
   不足なら引き上げ申請（承認に数時間〜1日かかることがある）。
2. **予算アラート**: AWS Budgets で月額予算（例: $30）を作成し、80%/100%でメール通知。
   **インスタンスの止め忘れは月$1,000超になる。**

### 1. インスタンス起動

| 設定 | 値 |
|---|---|
| リージョン | us-east-1（東京は2〜3割高い。SSHのみなので遅延は無関係） |
| AMI | Ubuntu Server 22.04 LTS (x86_64) — Canonical公式 |
| インスタンスタイプ | c7i.8xlarge（32 vCPU / 64 GiB）、オンデマンド約$1.43/h |
| ストレージ | gp3 500 GiB |
| セキュリティグループ | SSH(22) を自分のIPのみ許可 |
| シャットダウン動作 | 停止（デフォルト） |

スポット（約$0.53/h）も使えるが、中断されると途中からやり直しになる。初回はオンデマンド推奨。

### 2. ビルドパッケージ導入

LineageOS wiki（`lineage_wiki/_includes/templates/device_build_before_init.md`）準拠。

```bash
sudo apt update
sudo apt install -y bc bison build-essential ccache curl erofs-utils flex g++-multilib \
  gcc-multilib git git-lfs gnupg gperf imagemagick protobuf-compiler python3-protobuf \
  lib32readline-dev lib32z1-dev libdw-dev libelf-dev libgnutls28-dev lz4 libsdl1.2-dev \
  libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc \
  xxd zip zlib1g-dev lib32ncurses5-dev libncurses5 libncurses5-dev python-is-python3 tmux

mkdir -p ~/bin ~/android/lineage
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
echo 'export USE_CCACHE=1' >> ~/.bashrc
echo 'export CCACHE_EXEC=/usr/bin/ccache' >> ~/.bashrc
source ~/.bashrc
ccache -M 50G

git config --global user.name "<name>"
git config --global user.email "<email>"
git lfs install
```

JDK（OpenJDK 11）はソースに同梱されるため別途不要。

### 3. ソース取得

SSH切断でジョブが死なないよう、以降は `tmux` 内で実行する。

```bash
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-19.1 --git-lfs --depth=1
repo sync -c -j$(nproc) --no-tags --no-clone-bundle --optimized-fetch --prune
```

### 4. 環境検証ビルド（X00TD）

A6L用device treeは未作成のため、まず **ASUS Zenfone Max Pro M1 (X00TD)** でビルドが通ることを確認する。

X00TDを選ぶ理由: 公式LineageOSのSDM660系端末（lavender, jasmine_sprout, wayne, X01BD, platina）は
いずれも **18.1止まり**。19.1まで公式対応したのは SDM636（SDM660プラットフォームの派生）の
X00TD のみで、カーネルは **4.4.302**（`android_kernel_asus_sdm660`）。
A6L（SDM660 / kernel 4.4系）の構成に最も近い、19.1の公式実例でもある。

ベンダーblobはTheMuppetsから取得する:

```bash
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/muppets.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="themuppets" fetch="https://github.com/TheMuppets" />
  <project name="proprietary_vendor_asus" path="vendor/asus" remote="themuppets"
           revision="lineage-19.1" clone-depth="1" />
</manifest>
EOF

source build/envsetup.sh
breakfast X00TD          # device/asus/X00TD, sdm660-common, kernel を取得
repo sync -c -j$(nproc) --no-tags --no-clone-bundle   # local_manifests分
croot
brunch X00TD; sudo shutdown -h now
```

最後の `sudo shutdown -h now` でビルド終了後（成否に関わらず）インスタンスが停止する。
成功すると `out/target/product/X00TD/lineage-19.1-*-UNOFFICIAL-X00TD.zip` が生成される。
X00TD実機は無いので、ビルドが通ること自体が検証のゴール（ダウンロード不要）。

### 5. 後片付け

- **停止中もEBS代（500GB で約$40/月）は発生する。**
- 当面使わないなら、スナップショットを取ってボリュームを削除するか、インスタンスごと終了（terminate）する。
- P51へ移行したら、EC2のリソースはすべて削除する（ccache等の転送は不要。P51で再sync＋一晩ビルド）。

## 費用見積もり（us-east-1、2026-09時点）

| 項目 | 初回ビルド1回 |
|---|---|
| c7i.8xlarge オンデマンド 約4時間（準備30分＋sync 1時間＋ビルド2〜2.5時間） | 約$6 |
| EBS gp3 500GB（1日） | 約$1.3 |
| **合計** | **約$7** |

ビルド時間は32 vCPU構成からの推定値で、実測ではない。実測したらここを更新すること。
