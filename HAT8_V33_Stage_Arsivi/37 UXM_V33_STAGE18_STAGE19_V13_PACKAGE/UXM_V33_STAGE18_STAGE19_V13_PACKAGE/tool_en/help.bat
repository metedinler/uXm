@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
echo.
echo UXM English Tool Set V11
echo =========================
echo memory_test.bat       Run 16 MB memory-model tests
echo fast_scan.bat         Scan latest result CSV for failing keys
echo failed_test.bat       Rerun only unique failing tests
echo all_test.bat          Run all expected tests
echo workspace_clean.bat   Organize workspace; -u/--apply applies, -b retires build
echo report_show.bat       Show latest report
echo vscode_install.bat    Install VSCode extension
echo.
echo Options: -h, -k/--no-build, -D/--stop-on-fail, -n/--limit, -s/--from-index, -a/--name-contains, -z/--timeout-test, -u/--apply, -b/--retire-build
echo.
endlocal
