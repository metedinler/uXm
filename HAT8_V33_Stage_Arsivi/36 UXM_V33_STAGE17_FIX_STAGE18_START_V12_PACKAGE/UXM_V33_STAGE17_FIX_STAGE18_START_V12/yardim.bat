@echo off
chcp 65001 >nul
echo UXM Turkce komutlari
echo.
echo derleyici_derle.bat          Derleyiciyi derler
echo bellek_test.bat              Bellek modeli testleri
echo beklenen_duzelt.bat          .expect metaveri temizligi, -u ile uygular
echo stage17_duzelt.bat           Stage-17 beklenen cikti temizligini uygular
echo stage17_kontrol.bat          Stage-17/test-framework ilk 100 kontrol
echo hizli_tara.bat               Son sonuc CSV dosyasinda hatali anahtar tarar
echo hatali_test.bat -k -D        Sadece hatali anahtarlari kosar
echo tum_test.bat -k -n 100       Tum testlerden ilk 100
echo stage18_basla.bat            Stage-18 mega corpus testlerini baslatir
echo alan_topla.bat [-u] [-b]     Calisma alanini toparlar
echo rapor_goster.bat             Son raporu gosterir
echo vscode_kur.bat               VSCode UXM eklentisini kurar
echo.
echo Kisa secenekler: -h yardim, -k derleme-yok, -D ilk-hatada-dur, -n adet, -s basla, -a ara, -z zaman, -u uygula, -b build-emekli
