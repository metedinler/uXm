@echo off
setlocal
rem Gercek tasima yapar ve build/build stage klasorlerini Emekliler altina alir.
py -3 tools\uxm_ops\UXM_TOOL_LAUNCHER.py --tool workspace --apply --retire-build %*
endlocal
