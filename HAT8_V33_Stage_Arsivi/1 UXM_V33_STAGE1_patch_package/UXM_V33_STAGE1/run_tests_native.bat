@echo off
setlocal
call build_native.bat
if errorlevel 1 exit /b 1
for %%D in (uxm\tests\native uxm\tests\fp uxm\tests\matrix uxm\tests\math) do (
  if exist "%%D" for %%F in (%%D\*.uxm) do call build_one_native.bat "%%F"
  if errorlevel 1 exit /b 1
)
echo OK: native tests finished
endlocal
