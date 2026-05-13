@echo off
setlocal
call build_native_64k.bat
if errorlevel 1 exit /b 1
for %%D in (tests\stage12_native tests\stage12_v33 tests\stage12_fp tests\stage12_matrix tests\stage12_math) do (
  if exist "%%D" for %%F in (%%D\*.uxm) do call build_one_64k.bat "%%F" -x
  if errorlevel 1 exit /b 1
)
echo OK: UXM-A 64K smoke tests finished
endlocal
