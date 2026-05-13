@echo off
setlocal
REM UXM V6 - Sadece BUILD_FAIL/BUILD_OR_RUN_FAIL testlerini kosar.
py -3 tools\UXM_FAST_KEY_SCAN_V6.py --root .
if errorlevel 1 exit /b %errorlevel%
if exist fast_results\latest\failed_class_build_or_runtime_fail.csv (
  py -3 tools\UXM_EXPECT_RUNNER_V2.py --root . --manifest fast_results\latest\failed_class_build_or_runtime_fail.csv --stage fast_buildfail_v6 --out-root fast_results\runs %*
) else (
  echo [V6] build_or_runtime_fail manifesti yok. Once run_09_fast_key_scan.bat calistir.
)
exit /b %errorlevel%
