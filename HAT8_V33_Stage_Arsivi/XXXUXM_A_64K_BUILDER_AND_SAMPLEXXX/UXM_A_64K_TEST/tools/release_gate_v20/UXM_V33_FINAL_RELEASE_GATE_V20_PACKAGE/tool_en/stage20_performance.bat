@echo off
setlocal
python tool_en\uxm_stage20_final.py performans %*
exit /b %errorlevel%
