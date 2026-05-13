@echo off
setlocal
python tool_en\uxm_stage20_final.py placeholder %*
exit /b %errorlevel%
