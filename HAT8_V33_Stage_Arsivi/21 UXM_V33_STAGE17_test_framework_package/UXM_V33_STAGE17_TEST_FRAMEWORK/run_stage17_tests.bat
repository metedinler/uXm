@echo off
setlocal
REM Stage-17: expected/actual test framework smoke.
REM Eski testleri calistirmaz; sadece uxm\tests\stage17\*.uxm dosyalarini kosar.
if not exist tools\UXM_STAGE17_EXPECT_RUNNER.py (
  echo [HATA] tools\UXM_STAGE17_EXPECT_RUNNER.py bulunamadi.
  exit /b 1
)
py -3 tools\UXM_STAGE17_EXPECT_RUNNER.py --stage 17 --test-dir uxm\tests\stage17 --out-root stage17_results %*
exit /b %ERRORLEVEL%
