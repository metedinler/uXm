# Bölüm 11 — CLI, Terminal ve VSCode ile Kullanım

UXM terminal üzerinden çalıştırılan bir compiler/test sistemidir. Günlük kullanımda doğrudan compiler exe’si yerine `.bat` komutları kullanmak daha kolaydır. Bu `.bat` dosyaları Python araçlarını ve build scriptlerini doğru parametrelerle çağırır.

## Türkçe ve İngilizce araç dizinleri

Türkçe araçlar `araclar/` altında, İngilizce karşılıkları `tool_en/` altında tutulur. Bu ayrım önemlidir: Türkçe ana kullanımda terminal çıktıları, seçenek açıklamaları ve raporlar Türkçe olmalıdır; İngilizce dosyalar ise dış kullanıcı veya GitHub/VSCode paylaşımı için hazır tutulur.

| Komut | Görev | Sık kullanım |
|---|---|---|
| derleyici_derle.bat | Native compiler/runtime derleme hattını hazırlar | `derleyici_derle.bat` |
| bellek_test.bat | 16 MB bellek modeli ve tape/data/fifo smoke testleri | `bellek_test.bat` |
| tum_test.bat | Test klasörü veya manifest üzerinden toplu test çalıştırır | `tum_test.bat -k -n 100` |
| hizli_tara.bat | Son test CSV dosyasını tarar ve hatalı tekil manifest üretir | `hizli_tara.bat` |
| hatali_test.bat | Hızlı tarama manifestindeki hatalı testleri tekrar koşar | `hatali_test.bat -k -D` |
| rapor_goster.bat | Son RAPOR.md dosyasını terminalde gösterir | `rapor_goster.bat` |
| alan_topla.bat | Çalışma alanını temizler/toparlar; dry-run ve apply destekler | `alan_topla.bat -u -b` |
| stage17_tamamla.bat | Stage-17 test framework ve expect düzeltme kapısı | `stage17_tamamla.bat -k` |
| stage18_tamamla.bat | Stage-18 native bridge/mega corpus tamamlama kapısı | `stage18_tamamla.bat -k` |
| stage19_tamamla.bat | VSCode/diagnostic cleanup kapısı | `stage19_tamamla.bat -k` |
| stage20_tamamla.bat | Release/performance kalite kapısı | `stage20_tamamla.bat -k` |
| stage20_performans.bat | Exe-only timing, build cache ve release raporu üretimi | `stage20_performans.bat` |
| vscode_kur.bat | VSCode dil desteğini kullanıcı eklenti klasörüne kurar | `vscode_kur.bat` |
| stage_gorevleri.bat | Stage görev özetini gösterir | `stage_gorevleri.bat` |


| Command | Purpose | Typical use |
|---|---|---|
| tool_en\memory_test.bat | Run memory model tests | `tool_en\memory_test.bat` |
| tool_en\all_test.bat | Run all/selected tests | `tool_en\all_test.bat -k -n 100` |
| tool_en\fast_scan.bat | Scan latest result CSV for failures | `tool_en\fast_scan.bat` |
| tool_en\failed_test.bat | Re-run failed manifest only | `tool_en\failed_test.bat -k -D` |
| tool_en\workspace_clean.bat | Organize workspace | `tool_en\workspace_clean.bat -u -b` |
| tool_en\stage17_finish.bat | Finish Stage-17 test framework gate | `tool_en\stage17_finish.bat -k` |
| tool_en\stage18_finish.bat | Finish Stage-18 native bridge gate | `tool_en\stage18_finish.bat -k` |
| tool_en\stage19_cleanup.bat | VSCode/diagnostic cleanup | `tool_en\stage19_cleanup.bat` |
| tool_en\stage20_performance.bat | Performance/release report | `tool_en\stage20_performance.bat` |
| tool_en\vscode_install.bat | Install VSCode extension | `tool_en\vscode_install.bat` |


## VSCode kurulumu

```powershell
cd C:/Users/mete/Downloads/1/UXMv33
.scode_kur.bat
```

Kurulumdan sonra VSCode açıksa pencereyi yeniden yükle:

```text
Ctrl+Shift+P -> Developer: Reload Window
```

VSCode eklentisi `.uxm` dosyalarını tanır, temel syntax renklendirme ve snippet desteği verir. Snippet örnekleri `#memory`, `#cell`, `@N` servis çağrısı ve bellek test iskeletleri içerebilir.

## Terminalden compiler çalıştırma

Genel akış:

```powershell
.\derleyici_derle.bat
.ellek_test.bat
.	um_test.bat -k -n 100
.\hizli_tara.bat
.\hatali_test.bat -k -D
```

Eğer ilk 100 test temizse daha geniş test koşulur:

```powershell
.	um_test.bat -k
```

## Seçenekler

| Kısa seçenek | Uzun karşılık | Anlamı |
|---|---|---|
| `-h` | `--help` | Yardım gösterir. |
| `-k` | `--no-build` | Derleyiciyi yeniden derleme; mevcut derleyiciyle test koş. |
| `-D` | `--stop-on-fail` | İlk hata/uyuşmazlıkta dur. |
| `-n 100` | `--limit 100` | Sadece ilk N testi çalıştır. |
| `-s 50` | `--from-index 50` | Belirli sıradan başla. |
| `-a metin` | `--name-contains metin` | Adında metin geçen testleri çalıştır. |
| `-z 20` | `--timeout-test 20` | Tek test zaman aşımı. |
| `-u` | `--apply` | Dry-run değil, gerçek uygulama. |
| `-b` | `--retire-build` | Build çıktılarını emekli/arsiv alanına taşı. |


## Yeni başlayan için güvenli çalışma disiplini

Bir defada tüm sistemi koşturma. Önce `bellek_test.bat`, sonra 20–100 arası sınırlı test, sonra hızlı tarama, sonra sadece hatalı testler. Bu yöntem hem zamanı azaltır hem de gerçek hata ile test framework hatasını ayırmayı kolaylaştırır.
