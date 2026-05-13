# UX-MINIMA 6502 Dosya İnceleme Raporu

Bu rapor, yüklenen `.bas` dosyaları üzerinden 6502 uX Minima tarafını x64 sürümünden ayrı tutarak hazırlanmıştır.

## Dosya özeti

| Dosya | Satır | Pattern label | DATA çiftleri | Tekil pattern | Duplicate | Çakışmalı pattern | Dengesiz bracket | Not |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `patterbankasi1.bas` | 179 | 1 | 151 | 148 | 2 | 2 | 0 |  |
| `patternbank2.bas` | 103 | 1 | 85 | 84 | 0 | 0 | 0 |  |
| `patternbank4.bas` | 499 | 4 | 405 | 142 | 92 | 6 | 0 | çoklu PatternData, çoklu __END__ |
| `uxm_v2_compiler.bas` | 1704 | 0 | 0 | 0 | 0 | 0 | 0 | x64 ayrı tutulmalı |
| `uxm_v2_runtime.bas` | 152 | 0 | 0 | 0 | 0 | 0 | 0 | x64 ayrı tutulmalı |
| `uxminima.bas` | 266 | 1 | 135 | 120 | 15 | 4 | 4 | sabit DATA sayacı var |
| `uxminima_v2.bas` | 719 | 1 | 121 | 120 | 0 | 0 | 4 |  |
| `uxminmav1.bas` | 266 | 1 | 135 | 120 | 15 | 4 | 4 | uxminima.bas ile aynı, sabit DATA sayacı var |
| `uxminmav3.bas` | 158 | 1 | 2 | 1 | 0 | 0 | 0 | iskelet / eksik |

## En kritik bulgular

1. `uxminima.bas` ve `uxminmav1.bas` birebir aynı içeriktedir. Eski mimaride `Pat$(80)` tanımlı olduğu hâlde `DATA 135` okunur; bu büyüyen pattern bankasında taşma/çökme riski doğurur.
2. `uxminima_v2.bas` en sağlam 6502 compiler iskeletidir: `__END__` ile okur, duplicate pattern atlar, dengesiz bracket patternlerini filtreler ve uzunluk/spesifiklik sıralaması yapar.
3. `patternbank4.bas` tek dosyada birleştirilmiş/üst üste yapıştırılmış görünüyor: dört ayrı `PatternData:` etiketi ve beş ayrı `__END__` var. Bu hâliyle doğrudan include edilmemelidir.
4. `patterbankasi1.bas` en temiz geniş bankaya yakın dosyadır: 151 DATA çifti, 148 tekil pattern, sadece 2 duplicate ve 2 gerçek çakışma içerir.
5. x64 dosyaları (`uxm_v2_compiler.bas`, `uxm_v2_runtime.bas`) ayrı sistemdir; action tabanlı Windows x64 NASM üretir. 6502 string-ASM pattern bankasıyla karıştırılmamalıdır.

## Global tekilleştirme sonucu

- 6502 dosyalarından toplam pattern kaydı: **1024**
- Global tekil pattern sayısı: **211**
- Dengesiz bracket nedeniyle dışlanan tekil pattern sayısı: **4**
- Temizlenmiş review bankasına yazılan pattern sayısı: **207**
- Farklı ASM karşılığı bulunan çakışmalı pattern sayısı: **35**

## Çakışma örnekleri

| Pattern | Kaç kayıt | Kaç farklı ASM | Örnek kaynaklar |
|---|---:|---:|---|
| `0+@` | 11 | 4 | patterbankasi1.bas:31, patternbank2.bas:26, patternbank4.bas:26, patternbank4.bas:193, patternbank4.bas:303 |
| `+-+-` | 8 | 4 | patterbankasi1.bas:154, patternbank4.bas:160, patternbank4.bas:273, patternbank4.bas:383, patternbank4.bas:494 |
| `>><<` | 8 | 4 | patterbankasi1.bas:155, patternbank4.bas:159, patternbank4.bas:272, patternbank4.bas:382, patternbank4.bas:493 |
| `0.@` | 12 | 3 | patterbankasi1.bas:37, patterbankasi1.bas:139, patternbank2.bas:32, patternbank4.bas:32, patternbank4.bas:195 |
| `..` | 11 | 3 | patterbankasi1.bas:128, patternbank2.bas:96, patternbank4.bas:96, patternbank4.bas:251, patternbank4.bas:361 |
| `0++@` | 10 | 3 | patterbankasi1.bas:30, patterbankasi1.bas:163, patternbank2.bas:25, patternbank4.bas:25, patternbank4.bas:192 |
| `&&` | 9 | 3 | patterbankasi1.bas:116, patternbank2.bas:93, patternbank4.bas:93, patternbank4.bas:238, patternbank4.bas:348 |
| `0++++++++@` | 9 | 3 | patterbankasi1.bas:24, patternbank2.bas:19, patternbank4.bas:19, patternbank4.bas:186, patternbank4.bas:296 |
| `0+++++@` | 9 | 3 | patterbankasi1.bas:27, patternbank2.bas:22, patternbank4.bas:22, patternbank4.bas:189, patternbank4.bas:299 |
| `0++++@` | 9 | 3 | patterbankasi1.bas:28, patternbank2.bas:23, patternbank4.bas:23, patternbank4.bas:190, patternbank4.bas:300 |
| `0|` | 9 | 3 | patterbankasi1.bas:118, patternbank2.bas:95, patternbank4.bas:95, patternbank4.bas:242, patternbank4.bas:352 |
| `@@` | 9 | 3 | patterbankasi1.bas:33, patternbank2.bas:28, patternbank4.bas:28, patternbank4.bas:194, patternbank4.bas:304 |
| `||` | 9 | 3 | patterbankasi1.bas:117, patternbank2.bas:94, patternbank4.bas:94, patternbank4.bas:240, patternbank4.bas:350 |
| `0++++++@` | 6 | 3 | patterbankasi1.bas:26, patternbank2.bas:21, patternbank4.bas:21, patternbank4.bas:188, patternbank4.bas:298 |
| `0$` | 11 | 2 | patterbankasi1.bas:101, patternbank2.bas:83, patternbank4.bas:83, patternbank4.bas:233, patternbank4.bas:343 |
| `$0%` | 9 | 2 | patterbankasi1.bas:98, patternbank2.bas:80, patternbank4.bas:80, patternbank4.bas:230, patternbank4.bas:340 |
| `+++@` | 9 | 2 | patterbankasi1.bas:38, patternbank2.bas:33, patternbank4.bas:33, patternbank4.bas:199, patternbank4.bas:309 |
| `0+++++++@` | 9 | 2 | patterbankasi1.bas:25, patternbank2.bas:20, patternbank4.bas:20, patternbank4.bas:187, patternbank4.bas:297 |
| `0@` | 9 | 2 | patterbankasi1.bas:34, patternbank2.bas:29, patternbank4.bas:29, patternbank4.bas:198, patternbank4.bas:308 |
| `@.` | 9 | 2 | patterbankasi1.bas:36, patternbank2.bas:31, patternbank4.bas:31, patternbank4.bas:197, patternbank4.bas:307 |
| `@>` | 9 | 2 | patterbankasi1.bas:35, patternbank2.bas:30, patternbank4.bas:30, patternbank4.bas:196, patternbank4.bas:306 |
| `,.` | 7 | 2 | patterbankasi1.bas:134, patternbank4.bas:252, patternbank4.bas:362, patternbank4.bas:473, uxminima.bas:232 |
| `0+@>` | 7 | 2 | patterbankasi1.bas:32, patternbank2.bas:27, patternbank4.bas:27, patternbank4.bas:420, uxminima.bas:246 |
| `0+++@` | 6 | 2 | patterbankasi1.bas:29, patternbank2.bas:24, patternbank4.bas:24, patternbank4.bas:191, patternbank4.bas:301 |
| `&&&` | 5 | 2 | patterbankasi1.bas:112, patternbank4.bas:135, patternbank4.bas:239, patternbank4.bas:349, patternbank4.bas:460 |

## Dışlanan dengesiz bracket patternleri

- `[-][` -> uxminima.bas:209, uxminima_v2.bas:714, uxminmav1.bas:209
- `0[` -> uxminima.bas:210, uxminima_v2.bas:715, uxminmav1.bas:210
- `[[` -> uxminima.bas:252, uxminima_v2.bas:716, uxminmav1.bas:252
- `]]` -> uxminima.bas:253, uxminima_v2.bas:717, uxminmav1.bas:253

## Mimari karar önerisi

6502 için ana gövde `uxminima_v2.bas` üzerinden yürümeli. Pattern bankası tek dosya/tek label/tek `__END__` şeklinde tutulmalı. Sıralama elle değil, compiler açılışındaki `SortPatternsByPriority` ile yapılmalı: önce en uzun pattern, eşit uzunlukta en spesifik pattern, en sonda genel ve kısa pattern.

x64 tarafındaki `uxm_v2_compiler.bas` ayrı tutulmalı; çünkü orada patternler string ASM değil, action/arg tabanlı soyut emisyon modelidir. Bu model 6502’ye doğrudan taşınmamalı; ileride 6502 için de action tabanlı emit katmanı kurulursa ayrıca dönüştürülmelidir.

## Semantik risk notları

- Çok sayıda 6502 pattern içinde çıplak `INY`/`DEY` kullanılıyor. Ana tekil komutlarda page-boundary kontrolü var; fakat pattern içindeki çıplak hareketler `Y=255` veya `Y=0` sınırında `PTR+1` güncellemez. Bu, 6502 hedefinde gerçek doğruluk hatasıdır.
- `[>]` ve `[<]` gibi loop-scan patternleri tek adımlık kod gibi yazılmış; gerçek BF/UXM döngü semantiğini tam karşılamıyor. Bunlar safe bankaya alınmamalı veya gerçek label’lı scan koduna çevrilmelidir.
- `$` / `%` patternleri 6502 donanım stack’iyle `PHA/PLA` kullanıyor. Tekil `$` ve `%` desteklenmez veya dengesiz kullanılırsa return stack bozulabilir. UX için ayrı software stack daha güvenlidir.
- `@` meta çağrıları C64 ROM adreslerine doğrudan bağlıdır. `LOAD/SAVE` gibi KERNAL çağrıları tek başına `JSR $FFD5/$FFD8` ile tam doğru değildir; SETNAM/SETLFS/register hazırlığı gerekir.
- 6502 compiler lexer’ı yeni tasarlanan `~`, `{`, `}`, `;`, `:`, `sN`, `pN`, `kN` yüzeyini henüz taşımıyor. Bu özellikler x64 dosyada var ama 6502 uX Minima’da yok.
