@echo off
setlocal
py -3 araclar\uxm_test_kos.py -t uxm\tests\all_expected_known -o sonuclar_stage17 -n 100 %*
if errorlevel 1 python araclar\uxm_test_kos.py -t uxm\tests\all_expected_known -o sonuclar_stage17 -n 100 %*
