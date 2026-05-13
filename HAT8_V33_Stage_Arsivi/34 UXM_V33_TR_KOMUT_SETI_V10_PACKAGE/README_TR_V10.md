# UXM V10 Türkçe Komut Seti + Memory Smoke Düzeltmesi + VSCode Eklentisi

Bu paket V9 sonucundaki şu sorunları düzeltir:

1. `memory_model_v7` smoke `.expect` dosyalarında başlık metni beklenen çıktıya karışıyordu.
2. Byte hücreli memory-info testleri büyük cell sayısını 8-bit hücreye yazdığı için `0` görünüyor; yeni smoke testleri `#cell dword` ile doğru ölçer.
3. `UXM_FAST_KEY_SCAN_V9.py` CSV bulamazsa kırılıyordu; yeni `hizli.bat` son CSV'yi daha geniş arar.
4. Bat/Python yardım ve çıktı dili Türkçeleştirildi; kısa seçenekler eklendi.
5. VSCode için Türkçe/İngilizce komut adları olan basit UXM eklentisi eklendi.

## Ana komutlar

```powershell
yardim.bat
derle.bat
bellek.bat
hizli.bat
hata.bat -k -D
tum.bat -k -n 100
topla.bat
topla.bat -u
vscode_kur.bat
rapor.bat
```

## Kısa seçenekler

- `-h` veya `-H`: yardım
- `-k`: yeniden build yapmadan koş
- `-D`: ilk hatada dur
- `-n 50`: en fazla 50 test
- `-s 100`: 100. testten başla
- `-a metin`: test adında ara
- `-z 120`: timeout saniyesi
- `-u`: uygula
- `-b`: build klasörünü emekliye al

## V9 sonucu hakkında

Tensor4D testi V9'da geçti. Memory smoke derleniyor ama eski testlerin beklenenleri yanlış tasarlandığı için uyuşmazlık veriyordu. Bu paket `uxm/tests/bellek_v10` altında temiz bellek smoke seti verir.
