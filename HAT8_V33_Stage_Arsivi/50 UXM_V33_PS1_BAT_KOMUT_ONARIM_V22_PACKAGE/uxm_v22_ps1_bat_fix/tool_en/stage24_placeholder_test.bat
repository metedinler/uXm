@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0stage24_placeholder_test.ps1" %*
exit /b %ERRORLEVEL%
