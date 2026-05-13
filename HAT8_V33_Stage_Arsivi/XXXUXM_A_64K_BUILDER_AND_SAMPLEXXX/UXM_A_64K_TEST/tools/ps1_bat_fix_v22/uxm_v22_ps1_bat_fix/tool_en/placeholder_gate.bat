@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0placeholder_gate.ps1" %*
exit /b %ERRORLEVEL%
