@echo off
setlocal
py -3 tools\uxm_ops\UXM_TOOL_LAUNCHER.py --tool workspace --apply --retire-build %*
endlocal
