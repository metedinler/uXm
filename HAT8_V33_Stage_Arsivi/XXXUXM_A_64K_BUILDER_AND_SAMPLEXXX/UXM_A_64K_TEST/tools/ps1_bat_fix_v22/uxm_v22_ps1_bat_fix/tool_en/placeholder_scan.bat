@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0placeholder_scan.ps1" %*
exit /b %ERRORLEVEL%
