@echo off
setlocal
python araclar\uxm_stage20_final.py hepsi %*
exit /b %errorlevel%
