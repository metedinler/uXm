@echo off
setlocal
py -3 araclar\uxm_test_kos.py -t uxm\tests\mega_corpus -o sonuclar_stage18 %*
if errorlevel 1 python araclar\uxm_test_kos.py -t uxm\tests\mega_corpus -o sonuclar_stage18 %*
