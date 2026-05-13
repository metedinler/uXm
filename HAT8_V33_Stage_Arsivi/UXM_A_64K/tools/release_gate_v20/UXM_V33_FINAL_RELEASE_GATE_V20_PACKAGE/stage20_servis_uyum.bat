@echo off
setlocal
python araclar\uxm_stage20_final.py servis %*
exit /b %errorlevel%
