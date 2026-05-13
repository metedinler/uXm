param(
    [Alias('h','help')][switch]$Yardim,
    [Alias('k','kok','root')][string]$Kok = (Get-Location).Path,
    [Alias('d','derleme-yok','no-build')][switch]$DerlemeYok,
    [Alias('D','ilk-hatada-dur','stop-on-fail')][switch]$IlkHata,
    [Alias('n','adet','limit')][int]$Adet = 0,
    [Alias('s','basla','from-index')][int]$Basla = 1,
    [Alias('a','ara','name-contains')][string]$Ara = "",
    [Alias('z','zaman','timeout-test')][int]$Zaman = 45,
    [Alias('u','uygula','apply')][switch]$Uygula,
    [Alias('b','build-emekli','retire-build')][switch]$BuildEmekli
)
$Merkez = Join-Path $PSScriptRoot 'araclar\uxm_komut_merkezi.ps1'
if (!(Test-Path $Merkez)) { Write-Host "Komut merkezi bulunamadi: $Merkez" -ForegroundColor Red; exit 1 }
if ($Yardim) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Merkez -Komut yardim -Kok $Kok; exit $LASTEXITCODE }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Merkez -Komut 'tum_test' -Kok $Kok -DerlemeYok:$DerlemeYok -IlkHata:$IlkHata -Adet $Adet -Basla $Basla -Ara $Ara -Zaman $Zaman -Uygula:$Uygula -BuildEmekli:$BuildEmekli
exit $LASTEXITCODE
