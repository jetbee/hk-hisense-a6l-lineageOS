<!-- Copyright (C) 2026 jetbee -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# kernel/hisense/sdm660

ここにはカーネルのソースを置いていない。

- LineageOS 18.1 の版は、利用者が自分の端末の boot から取り出した**純正のカーネル**（4.4.153、Image.gz-dtb）と dtbo をそのまま使う。`scripts/extract-prebuilts.sh` が `vendor/hisense/hlte730t/prebuilt/` に置く（git には入れない）。
- Hisense は、このカーネルのソースを公開していない。GPL にもとづく開示を求めている。
- 純正のカーネルの主な設定（[docs/DEVICE.md](../../../docs/DEVICE.md)）：eBPF なし（Android 11 までは動く）、E-ink のパネルは Hisense 独自の fbdev のドライバ。
- 新しい Android（12 以降）では、公開されている SDM660 の新しいカーネルに、A6L の部品を移す予定（[docs/ROADMAP.md](../../../docs/ROADMAP.md)）。
