@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_test_et.py -d uxm\tests\bellek_v10 -c sonuclar_tr\bellek %*
if errorlevel 1 exit /b %ERRORLEVEL%
