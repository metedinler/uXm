@echo off
setlocal EnableExtensions
chcp 65001 >nul
python "%~dp0uxm_komut_merkezi.py" placeholder_kapi %*
exit /b %errorlevel%
