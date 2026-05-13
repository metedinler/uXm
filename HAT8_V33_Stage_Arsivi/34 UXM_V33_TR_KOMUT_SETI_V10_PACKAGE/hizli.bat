@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_hizli_tara.py -c hizli_sonuclar\son %*
if errorlevel 1 exit /b %ERRORLEVEL%
