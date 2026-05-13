@echo off
setlocal EnableExtensions
chcp 65001 >nul
python "%~dp0uxm_komut_merkezi.py" stage24_placeholder %*
exit /b %errorlevel%
