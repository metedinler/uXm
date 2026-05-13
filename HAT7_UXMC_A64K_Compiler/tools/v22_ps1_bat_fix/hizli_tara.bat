@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0hizli_tara.ps1" %*
exit /b %ERRORLEVEL%
