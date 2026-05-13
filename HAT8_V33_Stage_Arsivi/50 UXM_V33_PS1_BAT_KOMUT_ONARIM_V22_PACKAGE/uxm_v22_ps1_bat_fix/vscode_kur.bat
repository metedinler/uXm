@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0vscode_kur.ps1" %*
exit /b %ERRORLEVEL%
