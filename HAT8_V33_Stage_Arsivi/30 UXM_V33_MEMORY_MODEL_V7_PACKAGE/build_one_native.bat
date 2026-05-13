@echo off
setlocal EnableExtensions
if "%~1"=="" (echo Kullanim: build_one_native.bat kaynak.uxm [-x] & exit /b 1)
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
set NASM=nasm
if not exist build\exe mkdir build\exe
if not exist build\asm mkdir build\asm
if not exist build\obj mkdir build\obj
if not exist build\locks mkdir build\locks
if not exist build\exe\uxm_native.exe call build_native.bat
if errorlevel 1 exit /b 1
set NAME=%~n1
if /I "%~2"=="-x" (
  if not "%UXM_BUILD_ID%"=="" (
    set NAME=%UXM_BUILD_ID%
  ) else (
    set NAME=program
  )
)

set RUNTIME_SRC=uxm\core\runtime\uxm31_runtime_fb_full.bas
set RUNTIME_OBJ=build\obj\uxm_runtime_fb_full_cache.o
set RUNTIME_LOCK=build\locks\runtime_cache.lock
if not exist "%RUNTIME_OBJ%" goto build_runtime_cache
goto runtime_cache_ready

:build_runtime_cache
mkdir "%RUNTIME_LOCK%" 2>nul
if errorlevel 1 (
  echo Runtime cache baska islemde hazirlaniyor, bekleniyor...
  timeout /t 1 /nobreak >nul
  goto build_runtime_cache
)
echo Runtime cache derleniyor: %RUNTIME_OBJ%
"%FBC%" -c "%RUNTIME_SRC%" -o "%RUNTIME_OBJ%"
set CACHE_ERR=%ERRORLEVEL%
rmdir "%RUNTIME_LOCK%" 2>nul
if not "%CACHE_ERR%"=="0" exit /b %CACHE_ERR%

:runtime_cache_ready
build\exe\uxm_native.exe "%~1" "build\asm\%NAME%.asm"
if errorlevel 1 exit /b 1
echo NASM:
echo %NASM% -f win64 "build\asm\%NAME%.asm" -o "build\obj\%NAME%.o"
%NASM% -f win64 "build\asm\%NAME%.asm" -o "build\obj\%NAME%.o"
if errorlevel 1 exit /b 1
echo FreeBASIC runtime cache ile link:
echo %FBC% "%RUNTIME_OBJ%" "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
"%FBC%" "%RUNTIME_OBJ%" "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
if errorlevel 1 exit /b 1
"build\exe\%NAME%.exe"
endlocal
