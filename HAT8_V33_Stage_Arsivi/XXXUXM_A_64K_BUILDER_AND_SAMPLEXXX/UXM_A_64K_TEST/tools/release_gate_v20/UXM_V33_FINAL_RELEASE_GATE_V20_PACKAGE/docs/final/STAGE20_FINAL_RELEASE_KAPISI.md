# UXM Stage-20 Final Release Kapısı

Bu paket 8 maddelik placeholder/gerçek-kod planının son maddesidir. Amaç, “var” denilen servislerin gerçekten koda bağlı olup olmadığını otomatik raporlamak ve release öncesi kırmızı kapı kurmaktır.

## Görevler

1. Placeholder / dummy / TODO / stub taraması.
2. Servis registry ile runtime dispatch uyumu.
3. Kılavuzdaki servis referansları ile runtime uyumu.
4. Stage-20 final UXM test klasörü.
5. Exe-only timing raporu.
6. Build cache manifesti.
7. Servis tablosu otomatik üretimi.
8. Birleşik final rapor.

## Türkçe komutlar

```powershell
stage20_test.bat -k
stage20_placeholder_kapi.bat
stage20_servis_uyum.bat
stage20_kilavuz_uyum.bat
stage20_performans.bat
stage20_final_rapor.bat
stage20_release_kapi.bat -k
```

## İngilizce komutlar

```powershell
tool_en\stage20_test.bat -k
tool_en\stage20_placeholder_gate.bat
tool_en\stage20_service_alignment.bat
tool_en\stage20_guide_alignment.bat
tool_en\stage20_performance.bat
tool_en\stage20_final_report.bat
tool_en\stage20_release_gate.bat -k
```

## Kısa seçenekler

- `-k`: derleme yok / no-build
- `-D`: ilk hatada dur / stop-on-fail
- `-d`: dokümanları da placeholder taramasına dahil et
- `-n`: performans tekrar sayısı

## Karar mantığı

Kapı ancak şu durumda temiz sayılır:

- Stage-20 final testleri geçer.
- Kod içinde hata seviyesinde placeholder/dummy/TODO/stub kalmaz.
- Registry’de var denilen servis runtime dispatch içinde bulunur.
- Kılavuzda var görünen servis runtime dispatch içinde bulunur.
- Final rapor üretilir.

FreeBASIC/NASM koşusu kullanıcının Windows ortamında yapılmalıdır. Bu paket Python syntax olarak kontrol edilmiştir; gerçek compiler/test sonucu terminal çıktısıyla doğrulanacaktır.
