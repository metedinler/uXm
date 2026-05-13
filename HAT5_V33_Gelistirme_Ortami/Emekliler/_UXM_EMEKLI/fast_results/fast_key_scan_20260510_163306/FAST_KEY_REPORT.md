# UXM Fast Key Scan V6
Kaynak CSV: `expected_results_v2\all_expected_v2_20260510_141605\expected_results_v2.csv`
Toplam satır: **1054**
Hatalı/uyuşmaz satır: **37**
Benzersiz hatalı anahtar: **37**
Hızlı koşulacak unique manifest: `fast_results\latest\failed_unique_manifest.csv`
Tüm hatalı kopya manifesti: `fast_results\latest\failed_all_manifest.csv`

## Sınıf özeti
- memory_policy_data_directive: 37

## Önerilen hızlı sıra
1. `run_09_fast_key_scan.bat`
2. `run_10_rerun_failed_unique.bat --no-build` veya buildsiz değilse direkt `run_10_rerun_failed_unique.bat`
3. Unique anahtarlar temizlenirse `run_11_rerun_failed_all.bat --no-build`
