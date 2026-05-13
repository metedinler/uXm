@echo off
setlocal
python araclar\uxm_stage20_final.py performans %*
exit /b %errorlevel%
