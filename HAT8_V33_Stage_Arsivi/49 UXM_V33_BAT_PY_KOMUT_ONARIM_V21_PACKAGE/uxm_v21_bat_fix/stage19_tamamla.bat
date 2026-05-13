@echo off
setlocal EnableExtensions
chcp 65001 >nul
python "%~dp0araclar\uxm_komut_merkezi.py" stage19 %*
exit /b %errorlevel%
