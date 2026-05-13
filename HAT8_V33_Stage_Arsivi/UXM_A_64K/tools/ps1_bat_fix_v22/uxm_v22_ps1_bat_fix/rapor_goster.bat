@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0rapor_goster.ps1" %*
exit /b %ERRORLEVEL%
