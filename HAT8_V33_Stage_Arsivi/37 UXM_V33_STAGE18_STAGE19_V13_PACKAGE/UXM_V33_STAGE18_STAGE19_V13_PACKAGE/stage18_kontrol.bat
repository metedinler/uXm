@echo off
setlocal
py -3 araclar\uxm_test_kos.py -t uxm\tests\all_expected_known -a STAGE18 -o sonuclar_stage18 %*
if errorlevel 1 python araclar\uxm_test_kos.py -t uxm\tests\all_expected_known -a STAGE18 -o sonuclar_stage18 %*
