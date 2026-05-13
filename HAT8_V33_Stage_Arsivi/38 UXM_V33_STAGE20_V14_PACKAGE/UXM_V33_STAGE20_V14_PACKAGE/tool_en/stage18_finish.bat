@echo off
setlocal
call tool_en\stage18_fix.bat
call tool_en\stage18_check.bat %*
