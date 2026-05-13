@echo off
setlocal
python araclar\uxm_stage20_final.py kilavuz %*
exit /b %errorlevel%
