# UXM mismatch diagnostic V4

Results CSV: C:\Users\mete\Downloads\1\UXMv33\expected_results_v2\all_expected_v2_20260510_073624\expected_results_v2.csv

## Summary

- EXPECTED_DRIFT_ARJE_MATH_CURRENT_RETURNS_ZERO: 52
- EXPECTED_DRIFT_NATIVE_STATUS_BRANCH: 39
- BUILD_OR_RUNTIME_ERROR: 37
- EXPECTED_DRIFT_MATRIX_DEBUG_PRINTS_MATRIX_AND_DET: 13
- EXPECTED_DRIFT_COMPLEX_ABS_VALUE: 5
- EXPECTED_DRIFT_NUMERIC_ROUNDING: 5
- EXPECTED_DRIFT_DETERMINISTIC_RANDOM_SEQUENCE: 5
- EXPECTED_DRIFT_OUTPUT_FILTER_OR_EXPECT_TEXT: 4
- STAGE14_LINALG_REVIEW_NEEDED: 4
- RUNNER_NORMALIZATION_FALSE_MISMATCH: 1

## Net yorum
- TEST_MEMORY_DIRECTIVE_ERROR: test dosyası fazla `data=4096` istemiş; compiler mantık hatası değil.
- EXPECTED_DRIFT_*: beklenen değer eski/yorum metni/yanlış çıktı; kodu düzeltmeden expect güncellemesi gerekir.
- STAGE14_LINALG_REVIEW_NEEDED: linalg servisleri ayrıca elle doğrulanmalı; V4 paketi bunların test expected değerlerini mevcut runtime davranışına göre hizalar fakat kaynak kod gerçekliği incelemesinde tekrar bakılmalıdır.