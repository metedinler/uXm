@echo off
setlocal
python tool_en\uxm_stage20_final.py kilavuz %*
exit /b %errorlevel%
