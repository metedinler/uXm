# UXM V21 BAT/Python Komut Onarım Paketi

Bu paket, önceki paketlerde bozulan `.bat` sarmalayıcılarını ve tutarsız CLI anahtarlarını düzeltir.

## Neyi düzeltir?

- `etlocal` / `EM` gibi bozulmuş batch satırları.
- `-k` anahtarının bir yerde `derleme-yok`, başka yerde `kök` gibi kullanılması.
- `--fail-on-findings` ile `--hata-ver` çakışması.
- `araclar/uxm_test_kosucu.py` dosyası yok hatası.
- Yardım ekranlarının İngilizce/dağınık `argparse` çıktısı gibi görünmesi.
- Komut içine `cd` ve yol yazılınca parser'ın sapıtması.

## Yeni anahtar standardı

```text
-h,        --help                         Yardım ekranını gösterir.
-k,        --kok <yol>                    Proje kök dizini. Örnek: -k C:\UXMv33
-d,        --derleme-yok, --no-build       Derleyiciyi yeniden derlemeden test koşar.
-D,        --ilk-hatada-dur, --stop-on-fail İlk hatada durur.
-n,        --adet, --limit <sayı>          Koşulacak test sayısını sınırlar.
-s,        --basla, --from-index <sayı>    Test listesindeki başlangıç indeksi.
-a,        --ara, --name-contains <metin>  Dosya adında geçen testleri seçer.
-z,        --zaman, --timeout-test <sn>    Tek test zaman aşımı süresi.
-t,        --test-klasoru <yol>            Test klasörü.
-c,        --cikti <yol>                   Rapor/sonuç çıkış klasörü.
-u,        --uygula, --apply               Gerçek değişiklik uygular.
-b,        --build-emekli, --retire-build  Build klasörünü emekliye alır.
```

## Önemli kullanım kuralı

Komut içine `cd` yazılmaz.

Yanlış:

```powershell
.\stage21_placeholder_test.bat -k cd C:\Users\mete\Downloads\1\UXMv33
```

Doğru:

```powershell
cd C:\Users\mete\Downloads\1\UXMv33
.\stage21_placeholder_test.bat -d
```

Kök yolu özellikle vermek gerekirse:

```powershell
.\stage21_placeholder_test.bat -k C:\Users\mete\Downloads\1\UXMv33 -d
```

## Test sırası

```powershell
cd C:\Users\mete\Downloads\1\UXMv33
.\yardim.bat
.\bellek_test.bat
.\tum_test.bat -d -n 100
.\hizli_tara.bat
.\hatali_test.bat -d -D
.\placeholder_tara.bat
.\placeholder_kapi.bat
```

## İngilizce araçlar

İngilizce karşılıklar `tool_en/` altındadır:

```powershell
.\tool_en\help.bat
.\tool_en\memory_test.bat
.\tool_en\all_test.bat -d -n 100
.\tool_en\fast_scan.bat
.\tool_en\failed_test.bat -d -D
```
