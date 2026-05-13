# UXM Fast Key Scan V6
Kaynak CSV: `expected_results_v2/all_expected_v2_20260510_073624/expected_results_v2.csv`
Toplam satır: **1054**
Hatalı/uyuşmaz satır: **165**
Benzersiz hatalı anahtar: **54**
Hızlı koşulacak unique manifest: `/mnt/data/tmpfast/latest/failed_unique_manifest.csv`
Tüm hatalı kopya manifesti: `/mnt/data/tmpfast/latest/failed_all_manifest.csv`

## Sınıf özeti
- math_arge_expected_or_stub_review: 52
- native_status_branch_expected_review: 39
- memory_policy_data_directive: 37
- matrix_debug_extra_output: 13
- complex_expected_drift_abs_sqrt: 5
- numeric_rounding_expected_drift: 5
- deterministic_random_expected_drift: 5
- generic_mismatch_review: 4
- stage14_linalg_review: 4
- runner_false_positive_or_mode: 1

## Önerilen hızlı sıra
1. `run_09_fast_key_scan.bat`
2. `run_10_rerun_failed_unique.bat --no-build` veya buildsiz değilse direkt `run_10_rerun_failed_unique.bat`
3. Unique anahtarlar temizlenirse `run_11_rerun_failed_all.bat --no-build`
