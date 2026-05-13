@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0stage20_test.ps1" %*
exit /b %ERRORLEVEL%
