@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_compiler.ps1" %*
exit /b %ERRORLEVEL%
