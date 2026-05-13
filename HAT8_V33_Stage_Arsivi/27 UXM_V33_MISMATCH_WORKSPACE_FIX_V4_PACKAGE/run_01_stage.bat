@echo off
setlocal
if "%~1"=="" (echo Kullanim: run_01_stage.bat STAGE & exit /b 1)
py -3 UXM_STAGE_RUNNER_Y.py --stage %1 --scope stage
endlocal
