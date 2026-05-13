# Bölüm 13 — Test Framework, Stage-17/18/19/20 ve Release Kapısı

UXM projesinde test framework artık dilin kendisi kadar önemlidir. Çünkü compiler doğru olsa bile `.expect` okuyucu hatalıysa gerçek ve beklenen aynı olduğu halde test `UYUSMAZ` görünebilir. Stage-17’nin ana görevi bu yüzden expected/actual karşılaştırma mantığını sağlamlaştırmaktır.

## Stage görevleri

| Stage | Görev | Bu kılavuzdaki yeri |
|---|---|---|
| Stage-10 | FP, matrix/tensor temel kapısı, 16 MB memory modeli, eski servis regresyonu | Bölüm 5, 9, 13 |
| Stage-17 | .expect mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü | Bölüm 13 |
| Stage-18 | Final/ARGE + Native Bridge: eski ayrı parser/runner hattını native çekirdeğe yaklaştırma | Bölüm 4, 13 |
| Stage-19 | VSCode Integration Cleanup: internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama | Bölüm 11, 13 |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, dokümantasyon, servis tablosu otomasyonu | Bölüm 13, 14 |


## .expect formatları

`.expect` dosyasında beklenen çıktı tutulur. Mode satırları olabilir:

```text
# mode: compact
46.0000000000000000
```

Bazı eski dosyalarda `#source:embedded_EXPECT_OUTPUT` ön eki beklenen çıktıya yapışmış olabilir. Runner bu metaveriyi çıktı saymamalıdır. Stage-17 düzeltmesinin özü budur.

## Test modları

| Mod | Anlam |
|---|---|
| exact | Çıktı birebir aynı olmalı. |
| compact | Boşluk/satır farklarını temizleyip karşılaştır. |
| contains | Gerçek çıktı beklenen parçayı içeriyorsa başarılı. |
| contains_compact | Compact temizlenmiş içerme kontrolü. |

## Stage-18 native bridge

Stage-18, eski parser/runner hattı ile native çekirdek arasındaki farkları azaltır. Özellikle mega corpus, domain örnekleri ve tensor4d gibi köprü testleri burada önemlidir. Bir servis doğru çalışıyor gibi görünse bile gerekli dims/index bilgisi data alanına yazılmadan çağrılırsa sonuç `0` dönebilir; bu compiler hatası değil test hazırlama hatasıdır.

## Stage-19 VSCode cleanup

Stage-19, VSCode eklentisinin eski internal interpreter uyarılarını, final compiler build hatalarını, trace ve diagnostic hizalamasını temizler. Amaç editörün kullanıcıyı yanlış yönlendirmemesidir.

## Stage-20 performance/release cleanup

Stage-20, exe-only timing runner, build cache, dokümantasyon üretimi ve servis tablosu otomasyonunu kapsar. Release öncesi “bu paket çalışıyor mu?” sorusuna cevap verir.

## Çalıştırma örneği

```powershell
.\stage17_tamamla.bat -k
.\stage18_tamamla.bat -k
.\stage19_tamamla.bat -k
.\stage20_tamamla.bat -k
.\stage20_performans.bat
```
