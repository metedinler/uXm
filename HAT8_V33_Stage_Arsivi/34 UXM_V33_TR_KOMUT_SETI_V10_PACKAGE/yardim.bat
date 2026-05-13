@echo off
setlocal EnableExtensions
cd /d "%~dp0"
py -3 araclar\uxm_yardim.py %*
if errorlevel 1 python araclar\uxm_yardim.py %*
