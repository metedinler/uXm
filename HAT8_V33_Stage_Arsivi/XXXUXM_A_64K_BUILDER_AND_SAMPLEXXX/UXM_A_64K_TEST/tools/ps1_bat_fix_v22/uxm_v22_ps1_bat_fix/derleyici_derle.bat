@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0derleyici_derle.ps1" %*
exit /b %ERRORLEVEL%
