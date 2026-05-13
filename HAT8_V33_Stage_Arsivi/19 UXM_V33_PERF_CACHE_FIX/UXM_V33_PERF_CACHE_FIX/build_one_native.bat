@echo off
setlocal EnableExtensions
if "%~1"=="" (echo Kullanim: build_one_native.bat kaynak.uxm [-x] & exit /b 1)
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
set NASM=nasm
if not exist build\exe\uxm_native.exe call build_native.bat
if errorlevel 1 exit /b 1
if not exist build\asm mkdir build\asm
if not exist build\obj mkdir build\obj
if not exist build\exe mkdir build\exe
set NAME=%~n1
if /I "%~2"=="-x" set NAME=program

build\exe\uxm_native.exe "%~1" "build\asm\%NAME%.asm"
if errorlevel 1 exit /b 1

echo NASM:
echo %NASM% -f win64 "build\asm\%NAME%.asm" -o "build\obj\%NAME%.o"
%NASM% -f win64 "build\asm\%NAME%.asm" -o "build\obj\%NAME%.o"
if errorlevel 1 exit /b 1

set RT_SRC=uxm\core\runtime\uxm31_runtime_fb_full.bas
set RT_OBJ=build\obj\uxm_runtime_fb_full_cache.o
if not exist "%RT_OBJ%" call :BUILD_RUNTIME_CACHE

if exist "%RT_OBJ%" (
  echo FreeBASIC runtime cache ile link:
  echo %FBC% "%RT_OBJ%" "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
  %FBC% "%RT_OBJ%" "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
  if not errorlevel 1 goto RUN_EXE
  echo UYARI: cache link basarisiz. Kaynak runtime link fallback deneniyor.
)

echo FreeBASIC runtime kaynak ile link ^(fallback/yavas^):
echo %FBC% %RT_SRC% "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
%FBC% %RT_SRC% "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
if errorlevel 1 exit /b 1

:RUN_EXE
"build\exe\%NAME%.exe"
endlocal
exit /b 0

:BUILD_RUNTIME_CACHE
if exist "%RT_OBJ%" del /q "%RT_OBJ%" >nul 2>nul
echo Runtime cache derleniyor: %RT_OBJ%
%FBC% -c "%RT_SRC%" -o "%RT_OBJ%" > build\obj\uxm_runtime_cache_build.log 2>&1
if exist "%RT_OBJ%" exit /b 0
%FBC% -c "%RT_SRC%" >> build\obj\uxm_runtime_cache_build.log 2>&1
if exist "uxm31_runtime_fb_full.o" move /Y "uxm31_runtime_fb_full.o" "%RT_OBJ%" >nul
if exist "uxm\core\runtime\uxm31_runtime_fb_full.o" move /Y "uxm\core\runtime\uxm31_runtime_fb_full.o" "%RT_OBJ%" >nul
exit /b 0
