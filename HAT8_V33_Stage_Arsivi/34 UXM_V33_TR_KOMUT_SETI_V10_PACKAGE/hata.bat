@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call hizli.bat
if errorlevel 1 exit /b %ERRORLEVEL%
py -3 araclar\uxm_test_et.py -m hizli_sonuclar\son\hatali_tekil_manifest.csv -c sonuclar_tr\hatalilar %*
if errorlevel 1 exit /b %ERRORLEVEL%
