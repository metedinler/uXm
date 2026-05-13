@echo off
setlocal EnableExtensions
chcp 65001 >nul
python "%~dp0araclar\uxm_komut_merkezi.py" stage21_placeholder %*
exit /b %errorlevel%
