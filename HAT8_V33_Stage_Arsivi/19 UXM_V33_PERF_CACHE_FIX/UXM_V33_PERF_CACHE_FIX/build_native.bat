@echo off
setlocal EnableExtensions
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
if not exist build\exe mkdir build\exe
if not exist build\obj mkdir build\obj

%FBC% -lang fb uxm\core\compiler\native\uxm31_compiler_fb.bas -x build\exe\uxm_native.exe
if errorlevel 1 exit /b 1
echo OK: build\exe\uxm_native.exe

rem Runtime cache her compiler build sonrasi tazelenir.
rem Bu cache testlerde her seferinde runtime .bas derlemeyi engeller.
call :BUILD_RUNTIME_CACHE
endlocal
exit /b 0

:BUILD_RUNTIME_CACHE
set RT_SRC=uxm\core\runtime\uxm31_runtime_fb_full.bas
set RT_OBJ=build\obj\uxm_runtime_fb_full_cache.o
if exist "%RT_OBJ%" del /q "%RT_OBJ%" >nul 2>nul
echo Runtime cache derleniyor: %RT_OBJ%
%FBC% -c "%RT_SRC%" -o "%RT_OBJ%" > build\obj\uxm_runtime_cache_build.log 2>&1
if exist "%RT_OBJ%" (
  echo OK: %RT_OBJ%
  exit /b 0
)
rem Bazı FreeBASIC kurulumlarında -o davranışı farklı olabilir; ikinci güvenli deneme.
%FBC% -c "%RT_SRC%" >> build\obj\uxm_runtime_cache_build.log 2>&1
if exist "uxm31_runtime_fb_full.o" move /Y "uxm31_runtime_fb_full.o" "%RT_OBJ%" >nul
if exist "uxm\core\runtime\uxm31_runtime_fb_full.o" move /Y "uxm\core\runtime\uxm31_runtime_fb_full.o" "%RT_OBJ%" >nul
if exist "%RT_OBJ%" (
  echo OK: %RT_OBJ%
  exit /b 0
)
echo UYARI: Runtime cache olusturulamadi. build_one_native.bat yavas kaynak link fallback kullanacak.
exit /b 0
