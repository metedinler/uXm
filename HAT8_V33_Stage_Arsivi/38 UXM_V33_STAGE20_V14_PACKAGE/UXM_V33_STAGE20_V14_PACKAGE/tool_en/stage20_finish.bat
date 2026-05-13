@echo off
setlocal
cd /d %~dp0\..
call stage17_duzelt.bat
call stage18_duzelt.bat
call stage20_basla.bat %*
