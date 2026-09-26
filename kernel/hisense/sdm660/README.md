# kernel/hisense/sdm660

現在空。カーネルソースをここに置く。

## 入手方針（優先順）

1. Hisenseの GPL/OSSコンプライアンス窓口を確認し、公式カーネルソースの
   公開有無を調べる（Phase 3）。
2. 公式ソースが得られない場合、`boot.img`/`dtbo` からのDTB逆解析
   （実機からの読出し済みboot、[../../../docs/DEVICE.md](../../../docs/DEVICE.md)
   参照）と、近縁公開SDM660カーネル（他社SDM660機種のLineageOSカーネル）を
   出発点にして差分をHisense DTS相当に合わせる。

SDM660はLinux kernel 4.4系が一般的。
