@echo off
setlocal
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (
set FBC=%FBC64%
) else (
set FBC=fbc
)
set NASM=nasm
echo [1/4] Compiler derleniyor...
%FBC% uxm31_compiler_fb.bas -x uxm31_compiler.exe
if errorlevel 1 goto fail
echo [2/4] Test klasoru hazirlaniyor...
if not exist build mkdir build
echo [OK] Compiler hazir.
echo.
echo Kullanim:
echo   build_one.bat tests\test01_print_A.uxm
echo.
goto end
:fail
echo HATA: build_all.bat basarisiz oldu.
:end
endlocal