# UXM V33 Mevcut Dosya Akış Denetimi — Stage 12

Bu rapor yeni bat dosyası üretmeden, mevcut dosyaların görev sırasını ve durumunu gösterir.

| Tür | Dosya | Durum | Görev | Öneri | Not |
|---|---|---|---|---|---|
| bat | `build_native.bat` | AKTIF | compiler build | koru | fbc yolu var; yoksa PATH'teki fbc kullanılıyor |
| bat | `build_one_native.bat` | AKTIF | tek .uxm derle+link+çalıştır | koru; pause patch gerekirse küçük yama | optimizer için named exe modunda -x kullanma |
| bat | `rtx.bat` | LEGACY | eski sonucN logger | toparlayıcı ile emekli edilebilir | @ işaretli veri üretir |
| bat | `rtxz.bat` | LEGACY | eski sonucN logger varyantı | toparlayıcı ile emekli edilebilir | @ işaretli veri üretir |
| bat | `run_opt.bat` | DÜZELTME GEREK | optimizer zinciri | manager opt sırasını kullan | uxm_optimizer_pro.py çağırıyor ama zipte uxm_optimizer_pro2.py var |
| bat | `run_stage11_smoke.bat` | AKTIF | smoke + expected-output kapısı | önce çalıştır | Stage 12 smoke yoksa en yeni smoke olarak kullanılır |
| bat | `run_tests_native.bat` | YEDEK | basit full test | aktif hatta zorunlu değil | istatistik üretmez |
| bat | `runalltests.bat` | HATALI/LEGACY | eski full test | emekli et veya parantez düzelt | if/for kapanış parantezi eksik görünüyor |
| py | `UXMPerformansAnalizatoru.py` | AKTIF/YEDEK | test_history Excel raporu | koru | pandas/openpyxl ister |
| py | `UXM_Heavy_Asm_Optimizer.py` | ZAYIF | optimizer öneri raporu | kural kitabı genişlet | rules=[] boş; strateji_kitabi_v2 Kural Sayısı 0 üretiyor |
| py | `asmoptimizer.py` | DUPLICATE | isim yanıltıcı performans analiz kopyası | emekli adayı | ASM optimizer değil; UXMPerformansAnalizatoru ile aynı iş |
| py | `build_optimized.py` | AKTIF | yeni_optimize_asm derleme/link/çalıştırma | opt zincirinde çalıştır | FBC yolu sabit ama mevcutsa sorun yok |
| py | `stat.py` | LEGACY | eski log parser | emekli et | sonuc.txt arıyor; yeni sonucN akışıyla uyumsuz |
| py | `sts.py` | LEGACY | eski log parser | emekli et veya sadece referans | eski format varsayımları var |
| py | `stsx.py` | LEGACY | eski log parser/rapor | emekli et veya sadece referans | yeni manager doğrudan CSV üretir |
| py | `uxm_analizor(birlesik).py` | ANALIZ | birleşik analiz | koru | daha dolu analiz dosyası |
| py | `uxm_analizor.py` | ANALIZ | servis/analiz | koru | rapor üretmek için kullanılabilir |
| py | `uxm_analizor2.py` | ANALIZ | servis/analiz | koru | rapor üretmek için kullanılabilir |
| py | `uxm_optimizer_pro2.py` | AKTIF | orijinal/opt exe kıyas + sqlite | run_opt son adımı bu olmalı | run_opt yanlışlıkla pro.py çağırıyor |
| py | `zekiassop.py` | AKTIF AMA HARD-CODED | ASM örüntü analizi + optimize ASM üretimi | manager import ederek çalıştır | __main__ eski C:\Users\mete yoluna sabit |
| csv | `test_history.csv` | KORU | geçmiş/veri | aktif hatta veri kaynağı | test_history ve stats summary korunmalı |
| csv | `test_stats_summary.csv` | KORU | geçmiş/veri | aktif hatta veri kaynağı | test_history ve stats summary korunmalı |
| xlsx | `Performans_Raporu_20260508_0746.xlsx` | ARSIV | önceki rapor çıktısı | toparlayıcı ile rapor arşivine taşı | aktif girdi değil |
| xlsx | `Performans_Raporu_20260508_0820.xlsx` | ARSIV | önceki rapor çıktısı | toparlayıcı ile rapor arşivine taşı | aktif girdi değil |
| xlsx | `UXM_Performans_Analiz_Raporu_Final.xlsx` | ARSIV | önceki rapor çıktısı | toparlayıcı ile rapor arşivine taşı | aktif girdi değil |
| xlsx | `UXM_Performans_Raporu_Final.xlsx` | ARSIV | önceki rapor çıktısı | toparlayıcı ile rapor arşivine taşı | aktif girdi değil |
| optimizer | `optimizasyon/strateji_kitabi_v2.txt` | ZAYIF | ağır optimizer kural kitabı | kural seti doldur | mevcut dosyada Kural Sayısı: 0 |
