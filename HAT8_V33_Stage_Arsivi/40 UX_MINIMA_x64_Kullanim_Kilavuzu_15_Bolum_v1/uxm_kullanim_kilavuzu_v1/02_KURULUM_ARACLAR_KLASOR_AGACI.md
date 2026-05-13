# Bölüm 2 — Kurulum, Gerekli Araçlar ve Klasör Ağacı

UXM x64 hattı Windows üzerinde geliştirilmiş bir projedir. Güncel kullanımda temel araçlar şunlardır: FreeBASIC compiler, NASM assembler, Python 3, PowerShell veya CMD, Visual Studio Code ve proje içindeki `.bat`/`.py` yardımcı araçları. FreeBASIC compiler runtime ve test runner için kullanılır; NASM x64 assembly dosyalarını object dosyasına çevirmek için gereklidir; Python test koşucu, hızlı tarama, rapor üretimi, workspace toparlama ve VSCode kurulum işlerinde kullanılır.

## Bilgisayarda bulunması gereken araçlar

| Araç | Görev | Kontrol komutu |
|---|---|---|
| Python 3.10+ | Test runner, hızlı tarama, rapor, workspace toplama | `python --version` |
| FreeBASIC 1.10.x x64 | Compiler/runtime FreeBASIC kaynaklarını derleme | `fbc.exe -version` |
| NASM | Üretilen `.asm` dosyasını `.obj` dosyasına çevirme | `nasm -v` |
| PowerShell veya CMD | `.bat` dosyalarını çalıştırma | `powershell` |
| VSCode | UXM dosyalarını syntax highlight/snippet ile düzenleme | `code --version` |


## Temel klasör ağacı

```text
UXMv33/
├─ uxm/
│  ├─ core/
│  │  ├─ compiler/native/        # lexer, parser, adresleme, codegen, CLI
│  │  └─ runtime/                # bellek, status/flags, servis dispatch, runtime servisleri
│  └─ tests/                     # bellek, stage17, stage18, stage19, stage20, all_expected_known
├─ araclar/                      # Türkçe Python araçları
├─ tool_en/                      # İngilizce Python ve bat araçları
├─ ortak/                        # ortak runner çekirdeği
├─ vscode/                       # VSCode dil desteği ve kurulum scriptleri
├─ sonuclar_*                    # test rapor klasörleri
├─ hizli_sonuclar/               # hızlı tarama manifestleri
├─ build/                        # asm/obj/exe ara çıktıları
├─ *.bat                         # Türkçe ana komutlar
└─ README/manifest/diff dosyaları
```

## Türkçe komutlar

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


## İngilizce komutlar

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


## CLI seçenekleri

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


## İlk kurulum akışı

```powershell
cd C:/Users/mete/Downloads/1/UXMv33
.\derleyici_derle.bat
.ellek_test.bat
.scode_kur.bat
```

`bellek_test.bat` 5/5 geçiyorsa, temel derleme ve runtime hattı çalışıyor demektir. Ardından `tum_test.bat -k -n 100` ile ilk yüz regression testi denenir. `-k` burada “derleyiciyi tekrar derleme, mevcut compiler ile test koş” anlamına gelir.
