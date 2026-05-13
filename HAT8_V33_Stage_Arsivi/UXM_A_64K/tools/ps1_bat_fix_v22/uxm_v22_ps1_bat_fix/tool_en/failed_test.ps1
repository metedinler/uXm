param(
    [Alias('h','help')][switch]$Help,
    [Alias('k','root')][string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [Alias('d','no-build')][switch]$NoBuild,
    [Alias('D','stop-on-fail')][switch]$StopOnFail,
    [Alias('n','limit')][int]$Limit = 0,
    [Alias('s','from-index')][int]$FromIndex = 1,
    [Alias('a','name-contains')][string]$NameContains = "",
    [Alias('z','timeout-test')][int]$TimeoutTest = 45,
    [Alias('u','apply')][switch]$Apply,
    [Alias('b','retire-build')][switch]$RetireBuild
)
$Merkez = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'araclar\uxm_komut_merkezi.ps1'
if ($Help) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Merkez -Komut yardim -Kok $Root; exit $LASTEXITCODE }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Merkez -Komut 'hatali_test' -Kok $Root -DerlemeYok:$NoBuild -IlkHata:$StopOnFail -Adet $Limit -Basla $FromIndex -Ara $NameContains -Zaman $TimeoutTest -Uygula:$Apply -BuildEmekli:$RetireBuild
exit $LASTEXITCODE
