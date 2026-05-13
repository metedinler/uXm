param(
    [Parameter(Mandatory=$true)][string]$Komut,
    [string]$Kok = (Get-Location).Path,
    [switch]$DerlemeYok,
    [switch]$IlkHata,
    [int]$Adet = 0,
    [int]$Basla = 1,
    [string]$Ara = "",
    [int]$Zaman = 45,
    [switch]$Uygula,
    [switch]$BuildEmekli,
    [string]$TestKlasoru = "",
    [string]$Cikti = ""
)

$ErrorActionPreference = "Stop"
$script:Merkez = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ProjeKok = (Resolve-Path $Kok).Path

function Yaz-Baslik($metin) {
    Write-Host ""
    Write-Host "UX-MINIMA x64 :: $metin" -ForegroundColor Cyan
    Write-Host ("-" * (18 + $metin.Length)) -ForegroundColor DarkCyan
}

function Yaz-Yardim {
@"
UX-MINIMA x64 Komut Merkezi

Kullanim:
  .\<komut>.ps1 [secenekler]
  .\<komut>.bat [secenekler]

Genel secenekler:
  -h,        --help                         Kullaniciya yardim sunar.
  -k,        --kok <yol>                    Proje kok dizini. Ornek: -k C:\UXMv33
  -d,        --derleme-yok                  Derleyiciyi yeniden derlemeden test kosar.
  -D,        --ilk-hatada-dur               Ilk hata/uyusmazlikta durur.
  -n,        --adet <sayi>                  Kosulacak test sayisini sinirlar.
  -s,        --basla <sayi>                 Baslangic test indeksini belirler.
  -a,        --ara <metin>                  Test adinda metin arar.
  -z,        --zaman <saniye>               Tek test zaman asimi.
  -u,        --uygula                       Gercek islem yapar; verilmezse dry-run.
  -b,        --build-emekli                 Build klasorlerini Emekliler altina tasir.

Kok adresi komutun icine 'cd' olarak yazilmaz.
Dogru:
  .\stage21_placeholder_test.ps1 -d
  .\stage21_placeholder_test.ps1 -k C:\Users\mete\Downloads\1\UXMv33 -d

Yanlis:
  .\stage21_placeholder_test.ps1 -k cd C:\Users\mete\Downloads\1\UXMv33
"@ | Write-Host
}

function Python-Komut($argsList) {
    Push-Location $script:ProjeKok
    try {
        & python @argsList
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } finally {
        Pop-Location
    }
}

function Test-Kos($klasor, $ciktiKlasor) {
    Yaz-Baslik "Test kosusu"
    $args = @(
        (Join-Path $script:Merkez "uxm_test_kosucu.py"),
        "--kok", $script:ProjeKok,
        "--test-klasoru", $klasor,
        "--cikti", $ciktiKlasor,
        "--zaman", [string]$Zaman,
        "--basla", [string]$Basla
    )
    if ($DerlemeYok) { $args += "--derleme-yok" }
    if ($IlkHata) { $args += "--ilk-hatada-dur" }
    if ($Adet -gt 0) { $args += @("--adet", [string]$Adet) }
    if ($Ara -ne "") { $args += @("--ara", $Ara) }
    Python-Komut $args
}

function Hata-Tara {
    Yaz-Baslik "Hizli hata tarama"
    $args = @((Join-Path $script:Merkez "hizli_tara.py"), "--kok", $script:ProjeKok)
    Python-Komut $args
}

function Placeholder-Tara([switch]$Gate) {
    Yaz-Baslik "Placeholder tarama"
    $args = @((Join-Path $script:Merkez "placeholder_tara.py"), "--kok", $script:ProjeKok, "--cikti", "placeholder_raporu")
    if ($Gate) { $args += "--hata-ver" }
    Python-Komut $args
}

function Alan-Topla {
    Yaz-Baslik "Calisma alani toplama"
    $args = @((Join-Path $script:Merkez "alan_topla.py"), "--kok", $script:ProjeKok)
    if ($Uygula) { $args += "--uygula" }
    if ($BuildEmekli) { $args += "--build-emekli" }
    Python-Komut $args
}

function Rapor-Goster {
    Yaz-Baslik "Son rapor"
    $raporlar = Get-ChildItem -Path $script:ProjeKok -Recurse -Filter "RAPOR.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($raporlar.Count -eq 0) { Write-Host "RAPOR.md bulunamadi." -ForegroundColor Yellow; return }
    $son = $raporlar[0]
    Write-Host "RAPOR: $($son.FullName)" -ForegroundColor Green
    Get-Content $son.FullName -Encoding UTF8 | Select-Object -First 120
}

function Derleyici-Derle {
    Yaz-Baslik "Derleyici derleme"
    Push-Location $script:ProjeKok
    try {
        if (Test-Path ".\build_native.bat") { & cmd /c ".\build_native.bat" }
        else { Write-Host "build_native.bat bulunamadi." -ForegroundColor Red; exit 1 }
        exit $LASTEXITCODE
    } finally { Pop-Location }
}

function Vscode-Kur {
    Yaz-Baslik "VSCode eklentisi kurulum"
    $src = Join-Path $script:ProjeKok "vscode\uxm-dil-destegi-v11"
    $dst = Join-Path $env:USERPROFILE ".vscode\extensions\uxm-dil-destegi-v11"
    if (!(Test-Path $src)) { Write-Host "VSCode eklenti kaynak klasoru bulunamadi: $src" -ForegroundColor Yellow; return }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
    Write-Host "VSCode eklentisi kuruldu: $dst" -ForegroundColor Green
}

switch ($Komut) {
    "yardim" { Yaz-Yardim }
    "derleyici_derle" { Derleyici-Derle }
    "bellek_test" { Test-Kos "uxm\tests\bellek_v11" "sonuclar_bellek" }
    "tum_test" { Test-Kos "uxm\tests\all_expected_known" "sonuclar_tum" }
    "hizli_tara" { Hata-Tara }
    "hatali_test" { Test-Kos "hizli_sonuclar\son\hatali_tekil_manifest.csv" "sonuclar_hatali" }
    "placeholder_tara" { Placeholder-Tara }
    "placeholder_kapi" { Placeholder-Tara -Gate }
    "stage21_placeholder_test" { Test-Kos "uxm\tests\stage21_placeholder_real" "sonuclar_stage21" }
    "stage22_placeholder_test" { Test-Kos "uxm\tests\stage22_placeholder_real" "sonuclar_stage22" }
    "stage23_placeholder_test" { Test-Kos "uxm\tests\stage23_placeholder_real" "sonuclar_stage23" }
    "stage24_placeholder_test" { Test-Kos "uxm\tests\stage24_placeholder_v19" "sonuclar_stage24" }
    "stage20_release_kapi" {
        Test-Kos "uxm\tests\stage20_final" "sonuclar_stage20"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Placeholder-Tara -Gate
    }
    "stage20_test" { Test-Kos "uxm\tests\stage20_final" "sonuclar_stage20" }
    "alan_topla" { Alan-Topla }
    "rapor_goster" { Rapor-Goster }
    "vscode_kur" { Vscode-Kur }
    default { Write-Host "Bilinmeyen komut: $Komut" -ForegroundColor Red; Yaz-Yardim; exit 2 }
}
