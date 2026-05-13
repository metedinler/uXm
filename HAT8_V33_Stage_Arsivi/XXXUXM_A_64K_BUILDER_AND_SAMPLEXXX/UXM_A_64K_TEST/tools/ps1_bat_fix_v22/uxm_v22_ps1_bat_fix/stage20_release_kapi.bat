@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0stage20_release_kapi.ps1" %*
exit /b %ERRORLEVEL%
