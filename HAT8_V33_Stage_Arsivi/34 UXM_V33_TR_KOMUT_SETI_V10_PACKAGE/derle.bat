@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call build_native.bat %*
