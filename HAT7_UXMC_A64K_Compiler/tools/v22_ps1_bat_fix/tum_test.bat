@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tum_test.ps1" %*
exit /b %ERRORLEVEL%
