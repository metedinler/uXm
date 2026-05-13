@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0workspace_clean.ps1" %*
exit /b %ERRORLEVEL%
