@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_vscode_kur.py %*
if errorlevel 1 exit /b %ERRORLEVEL%
