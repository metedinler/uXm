@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0yardim.ps1" %*
exit /b %ERRORLEVEL%
