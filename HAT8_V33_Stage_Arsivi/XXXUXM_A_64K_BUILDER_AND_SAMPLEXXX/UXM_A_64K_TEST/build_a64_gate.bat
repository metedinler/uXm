@echo off
setlocal
cd /d "%~dp0"
if not exist build mkdir build

echo [1/4] FreeBASIC native compiler derleme
fbc src\uxm_v20_native_compiler.bas -x build\uxm_a64_native_compiler.exe
if errorlevel 1 goto fail

echo [2/4] FreeBASIC runtime object derleme
fbc src\uxm_v20_runtime.bas -c -o build\uxm_a64_runtime.o
if errorlevel 1 goto fail

echo [3/4] Placeholder ve 64KB statik kapi
python tools\uxm_a64_static_gate.py
if errorlevel 1 goto fail

echo [4/4] Bitti. NASM/EXE smoke testlerini ortam pathlerine gore calistirin.
goto end

:fail
echo HATA: UXM-A-64K gate basarisiz.
exit /b 1
:end
endlocal
