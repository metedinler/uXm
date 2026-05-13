@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0alan_topla.ps1" %*
exit /b %ERRORLEVEL%
