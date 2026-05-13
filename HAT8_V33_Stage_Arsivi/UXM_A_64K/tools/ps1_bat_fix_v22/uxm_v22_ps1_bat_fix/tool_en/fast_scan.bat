@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fast_scan.ps1" %*
exit /b %ERRORLEVEL%
