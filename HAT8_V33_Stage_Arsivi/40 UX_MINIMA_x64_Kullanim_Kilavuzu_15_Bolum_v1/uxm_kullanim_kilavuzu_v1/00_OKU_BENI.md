# UX-MINIMA x64 Kullanım Kılavuzu — 15 Bölümlük Okuma Haritası

Bu paket, UX-MINIMA x64 yani kısa adıyla **UXM** için 15 bölümlük Türkçe kullanım kılavuzudur. Kılavuzun hedef kitlesi, BASIC veya Python gibi bir dili tanıyan ama henüz büyük bir sistem yazmamış 15–25 yaş arası öğrenciler ve hobi geliştiricilerdir.

UXM’yi öğrenirken kafanda şu resmi kur: Program bir yandan **tape** üzerinde yürüyen küçük komutlardan oluşur, diğer yandan `@N` servis çağrılarıyla matematik, dosya, string, matrix, tensor, istatistik ve benzeri büyük işleri runtime servislerine yaptırır.

## Bölüm sırası

| Bölüm | Dosya | Konu |
|---|---|---|
| 2 | 01_GIRIS_DIL_NEDIR.md | Bölüm 1 — UX-MINIMA x64 Nedir, Ne İşe Yarar? |
| 3 | 02_KURULUM_ARACLAR_KLASOR_AGACI.md | Bölüm 2 — Kurulum, Gerekli Araçlar ve Klasör Ağacı |
| 4 | 03_KAYNAK_DOSYA_VE_SOZDIZIMI.md | Bölüm 3 — UXM Kaynak Dosyası, Direktifler ve Temel Sözdizimi |
| 5 | 04_MIMARI_ARTIFACT_AKIS.md | Bölüm 4 — Sistem Mimarisi, Artifact ve Derleme Akışı |
| 6 | 05_BELLEK_MODELI.md | Bölüm 5 — Tape, Data, Stack, FIFO ve 16 MB Bellek Modeli |
| 7 | 06_ADRESLEME_MODLARI.md | Bölüm 6 — Adresleme Modları ve Küçük Komutların Davranışı |
| 8 | 07_SERVISLER_CEKIRDEK_ARITMETIK_IO.md | Bölüm 7 — Çekirdek, Aritmetik, Matematik ve I/O Servisleri |
| 9 | 08_BILIMSEL_SERVISLER_FP_ISTATISTIK_NUMERIC.md | Bölüm 8 — Floating Point, İstatistik, Olasılık, Sayısal Yöntem ve Bilimsel Servisler |
| 10 | 09_MATRIX_TENSOR_LISTE_SOZLUK_KUME.md | Bölüm 9 — Liste, Sözlük, Küme, Matrix ve Tensor Mantığı |
| 11 | 10_STRING_DOSYA_BIO_ML_SERVISLERI.md | Bölüm 10 — String, Dosya, BIO, ML ve Veri Pipeline Servisleri |
| 12 | 11_CLI_VSCODE_KULLANIM.md | Bölüm 11 — CLI, Terminal ve VSCode ile Kullanım |
| 13 | 12_ASM_OBJ_JSON_DOSYA_YAPILARI.md | Bölüm 12 — ASM, OBJ, JSON, CSV ve Rapor Dosyaları |
| 14 | 13_TEST_FRAMEWORK_STAGE_17_20.md | Bölüm 13 — Test Framework, Stage-17/18/19/20 ve Release Kapısı |
| 15 | 14_SERVIS_KATALOGU.md | Bölüm 14 — Tam Servis Kataloğu |
| 16 | 15_ORNEKLER_OGRENME_YOLU.md | Bölüm 15 — Örneklerle Öğrenme Yolu ve Büyük Program Kurma Mantığı |


## Stage görevleri

| Stage | Görev | Bu kılavuzdaki yeri |
|---|---|---|
| Stage-10 | FP, matrix/tensor temel kapısı, 16 MB memory modeli, eski servis regresyonu | Bölüm 5, 9, 13 |
| Stage-17 | .expect mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü | Bölüm 13 |
| Stage-18 | Final/ARGE + Native Bridge: eski ayrı parser/runner hattını native çekirdeğe yaklaştırma | Bölüm 4, 13 |
| Stage-19 | VSCode Integration Cleanup: internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama | Bölüm 11, 13 |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, dokümantasyon, servis tablosu otomasyonu | Bölüm 13, 14 |


## İlk önerilen okuma

Önce `01_GIRIS_DIL_NEDIR.md`, `03_KAYNAK_DOSYA_VE_SOZDIZIMI.md`, `05_BELLEK_MODELI.md` ve `06_ADRESLEME_MODLARI.md` dosyalarını oku. Sonra örnekleri çalıştır. Servislerin tamamını görmek için `14_SERVIS_KATALOGU.md` dosyasına bak.
