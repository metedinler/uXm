@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_test_et.py -d uxm\tests\all_expected_known -c sonuclar_tr\tum -k %*
if errorlevel 1 exit /b %ERRORLEVEL%
