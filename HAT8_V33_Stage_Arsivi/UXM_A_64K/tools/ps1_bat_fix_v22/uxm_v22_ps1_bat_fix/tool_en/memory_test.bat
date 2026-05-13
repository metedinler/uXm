@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0memory_test.ps1" %*
exit /b %ERRORLEVEL%
