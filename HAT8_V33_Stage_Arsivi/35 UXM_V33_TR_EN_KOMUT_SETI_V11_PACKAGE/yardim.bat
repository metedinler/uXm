@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
if "%~1"=="-h" goto help
if "%~1"=="--help" goto help
:help
echo.
echo UXM Turkce Ana Komut Seti V11
echo ===============================
echo.
echo yardim.bat             Bu ekran
echo derleyici_derle.bat    Ana UXM derleyicisini derler
echo bellek_test.bat        16 MB esnek bellek modeli testleri
echo hizli_tara.bat         Son sonuc CSV dosyasindan hatali anahtarlari cikarir
echo hatali_test.bat        Sadece hatali tekil testleri yeniden kosar
echo tum_test.bat           Beklenen degeri olan tum testleri kosar
echo alan_topla.bat         Calisma alanini toparlar; -u uygular, -b build'i emekliye alir
echo rapor_goster.bat       Son raporu/ozeti gosterir
echo vscode_kur.bat         VSCode UXM dil destegi eklentisini kurar
echo.
echo Anlamli kisa secenekler:
echo   -h  yardim              --help
echo   -k  derleme-yok         --no-build
echo   -D  ilk-hatada-dur      --stop-on-fail
echo   -n  adet                --limit
echo   -s  basla               --from-index
echo   -a  ara                 --name-contains
echo   -z  zaman               --timeout-test
echo   -u  uygula              --apply
echo   -b  build-emekli        --retire-build
echo.
echo Ornekler:
echo   bellek_test.bat
echo   hizli_tara.bat
echo   hatali_test.bat -k -D
echo   tum_test.bat -k -n 100
echo   alan_topla.bat
echo   alan_topla.bat -u -b
echo   vscode_kur.bat
echo.
endlocal
