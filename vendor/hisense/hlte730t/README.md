<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# vendor/hisense/hlte730t

このリポジトリでは、ここは空のまま。ビルドの前に、利用者が自分の端末から取り出したものを置く。git には入れない（`.gitignore`）。

| 置くもの | 作り方 |
|---|---|
| `prebuilt/Image.gz-dtb`、`prebuilt/dtbo.img`、`prebuilt/vendor.img` | `scripts/extract-prebuilts.sh <読み出したイメージのフォルダ> <LineageOS のソース>` |
| `proprietary/`（第 2 段階用。第 1 段階では使わない） | 純正の vendor を読み取り専用でマウントして、`device/hisense/hlte730t/extract-files.sh <マウント先の親>` |

## 注意

- IMEI や無線の校正値など、端末ごとのファイル（modemst、fsg、persist、QCN、EFS）は対象外。`proprietary-files.txt` に入れない。
- ブロブとイメージは Hisense や Qualcomm などのもの。再配布しない。
