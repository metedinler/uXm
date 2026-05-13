@echo off
setlocal EnableExtensions

echo [STEP 0] Proje servis haritasi guncelleniyor...
python "uxm_analizor(birlesik).py"
if errorlevel 1 exit /b 1

echo [STEP 1] ASM Intelligence raporu ve optimize ASM adaylari uretiliyor...
python zekiassop.py
if errorlevel 1 exit /b 1

echo [STEP 2] Agir siklet optimizasyon onerileri uretiliyor...
python UXM_Heavy_Asm_Optimizer.py
if errorlevel 1 exit /b 1

echo [STEP 3] Optimize ASM dosyalari derleniyor ve olculuyor...
python build_optimized.py
if errorlevel 1 exit /b 1

echo [STEP 4] Orijinal ve optimize EXE karsilastiriliyor, SQLite kaydi yaziliyor...
python uxm_optimizer_pro2.py
if errorlevel 1 exit /b 1

echo Analiz tamamlandi. Veritabani: optimizasyon\uxm_perf_history.db
pause
