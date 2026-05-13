@echo off
setlocal
python araclar\uxm_stage20_final.py test %*
exit /b %errorlevel%
