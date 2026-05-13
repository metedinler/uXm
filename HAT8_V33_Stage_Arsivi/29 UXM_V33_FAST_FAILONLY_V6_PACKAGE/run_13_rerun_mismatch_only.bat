@echo off
setlocal
REM UXM V6 - BUILD_FAIL haric, UYUSMAZ/mismatch siniflarini hizli kosar.
py -3 tools\UXM_FAST_KEY_SCAN_V6.py --root . --include-status UYUSMAZ,EXIT_MISMATCH
if errorlevel 1 exit /b %errorlevel%
py -3 tools\UXM_EXPECT_RUNNER_V2.py --root . --manifest fast_results\latest\failed_unique_manifest.csv --stage fast_mismatch_unique_v6 --out-root fast_results\runs %*
exit /b %errorlevel%
