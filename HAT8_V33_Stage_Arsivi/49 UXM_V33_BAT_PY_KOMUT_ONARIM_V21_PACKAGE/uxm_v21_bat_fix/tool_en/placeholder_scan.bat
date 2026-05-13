@echo off
setlocal EnableExtensions
chcp 65001 >nul
python "%~dp0uxm_command_center.py" placeholder_scan %*
exit /b %errorlevel%
