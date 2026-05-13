@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0help.ps1" %*
exit /b %ERRORLEVEL%
