# device/hisense/hlte730t

現在空。LineageOS device tree（`BoardConfig.mk`, `device.mk`,
`AndroidProducts.mk`, `vendorsetup.sh`, init rc, sepolicy等）をここに置く。

## ここを埋めるために次に必要な入力

1. **stock system/vendor partition imageのmount結果**
   （`system_live_dump.img` / stock TFパッケージから取得、Phase 2）
   → `proprietary-files.txt` の元になる。
2. **boot.img / dtboの解析結果**（`aospdtgen`等）
   → `BoardConfig.mk` の初期値（パーティションサイズ、DTB形式、カーネル
   ビルド設定）。実測GPT値は [../../../docs/DEVICE.md](../../../docs/DEVICE.md)
   参照。
3. **カーネルソース**（`kernel/hisense/sdm660/`、Phase 3）
   → `BoardConfig.mk` の `TARGET_KERNEL_SOURCE` 等。
4. **WSL/Linuxビルド環境**（Phase 1）
   → `breakfast`/`lunch` での動作確認。

これらが揃うまでは着手しない（推測でBoardConfigを書くと後戻りが大きい）。
