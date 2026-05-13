# UXM Stage Runner Politika Düzeltmesi

Mete abi'nin kararı:
- Mevcut bat/test dosyaları tekrar üretilmeyecek.
- Yeni stage paketinde sadece o stage'in yeni testleri olacak.
- Runner mevcut dosyaları sırayla çalıştıracak; aynı işi yapan yeni bat dosyaları üretmeyecek.
- Rapor XLSX hatası test sonucunu başarısız saymayacak.
- Raw log aynen saklanacak; XLSX/CSV için kontrol karakterleri sanitize edilecek.

## Runner davranışı

1. `build_native.bat` çağır.
2. Elindeki mevcut test listelerini sırayla çalıştır.
3. `build_one_native.bat` üzerinden derle/çalıştır.
4. Gerçek output'u raw loga yaz.
5. Beklenen çıktı varsa `.expect` ile karşılaştır.
6. CSV/XLSX'e yazarken kontrol karakterlerini `\\x00`, `\\x01` gibi görünür metne çevir.
7. XLSX yazılamazsa testleri bozma; sadece `.xlsx_error.txt` üret.

## IllegalCharacterError nedeni

Branch/current-zero gibi testler `\x00B` veya `\x01B` üretebilir. Konsolda ve raw logda bu normaldir; ancak XLSX XML formatı bu karakterleri hücre içinde kabul etmez.
