$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Join-Path $Root "uxm-turkce"
$Dst = Join-Path $env:USERPROFILE ".vscode\extensions\metedinler.uxm-turkce-v10"
if (!(Test-Path $Src)) { throw "Eklenti kaynağı bulunamadı: $Src" }
if (Test-Path $Dst) { Remove-Item $Dst -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Split-Path $Dst) | Out-Null
Copy-Item $Src $Dst -Recurse -Force
Write-Host "UXM Türkçe VSCode eklentisi kuruldu: $Dst"
Write-Host "VSCode açıksa: Ctrl+Shift+P -> Developer: Reload Window"
