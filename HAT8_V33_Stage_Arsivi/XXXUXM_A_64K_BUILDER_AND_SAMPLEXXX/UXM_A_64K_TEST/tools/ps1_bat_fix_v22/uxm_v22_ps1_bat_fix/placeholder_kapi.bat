@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0placeholder_kapi.ps1" %*
exit /b %ERRORLEVEL%
