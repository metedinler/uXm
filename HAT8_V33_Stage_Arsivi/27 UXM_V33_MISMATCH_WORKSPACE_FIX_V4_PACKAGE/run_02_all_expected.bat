@echo off
setlocal
if exist run_all_expected_tests_v2.bat (call run_all_expected_tests_v2.bat %*) else (call run_all_expected_tests.bat %*)
endlocal
