@echo off
setlocal
python araclar\uxm_stage20_final.py placeholder %*
exit /b %errorlevel%
