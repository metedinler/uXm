@echo off
setlocal
py -3 araclar\uxm_test_kos.py -m manifests\stage19_manifest.csv -o sonuclar_stage19 %*
if errorlevel 1 python araclar\uxm_test_kos.py -m manifests\stage19_manifest.csv -o sonuclar_stage19 %*
