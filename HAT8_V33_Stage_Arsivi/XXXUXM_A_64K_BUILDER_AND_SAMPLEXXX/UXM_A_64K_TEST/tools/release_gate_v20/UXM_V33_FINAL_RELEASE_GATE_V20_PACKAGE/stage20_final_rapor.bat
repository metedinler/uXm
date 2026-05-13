@echo off
setlocal
python araclar\uxm_stage20_final.py rapor %*
exit /b %errorlevel%
