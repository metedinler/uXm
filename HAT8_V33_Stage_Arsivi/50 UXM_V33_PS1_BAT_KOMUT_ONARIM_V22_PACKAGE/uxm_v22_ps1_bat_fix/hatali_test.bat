@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0hatali_test.ps1" %*
exit /b %ERRORLEVEL%
