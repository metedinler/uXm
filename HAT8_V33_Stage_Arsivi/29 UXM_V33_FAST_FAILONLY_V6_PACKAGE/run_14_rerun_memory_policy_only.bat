@echo off
setlocal
REM UXM V6 - data bellek siniri gibi memory policy kaynakli fail siniflarini kosar.
py -3 tools\UXM_FAST_KEY_SCAN_V6.py --root .
if errorlevel 1 exit /b %errorlevel%
if exist fast_results\latest\failed_class_memory_policy_data_directive.csv (
  py -3 tools\UXM_EXPECT_RUNNER_V2.py --root . --manifest fast_results\latest\failed_class_memory_policy_data_directive.csv --stage fast_memory_policy_v6 --out-root fast_results\runs %*
) else (
  echo [V6] memory_policy_data_directive manifesti yok.
)
exit /b %errorlevel%
