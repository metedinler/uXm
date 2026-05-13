@echo off
setlocal
py -3 tool_en\uxm_test_run.py -t uxm\tests\all_expected_known -o results_stage17 -n 100 %*
if errorlevel 1 python tool_en\uxm_test_run.py -t uxm\tests\all_expected_known -o results_stage17 -n 100 %*
