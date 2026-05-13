@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_toparla.py %*
if errorlevel 1 exit /b %ERRORLEVEL%
