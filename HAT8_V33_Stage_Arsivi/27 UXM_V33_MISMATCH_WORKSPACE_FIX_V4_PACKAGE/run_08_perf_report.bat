@echo off
setlocal
if exist UXM_TIMING_ANALYZER_V2.py (py -3 UXM_TIMING_ANALYZER_V2.py %*) else echo UXM_TIMING_ANALYZER_V2.py bulunamadi.
endlocal
