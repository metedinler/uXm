# UXM V22 Komut Standardı

Bu paket eski uyuma göre değil, yeni temiz standarda göre yazıldı.

## Kural

- PowerShell dosyaları gerçek komuttur: `*.ps1`.
- BAT dosyaları sadece aynı adlı PS1 dosyasını çağırır.
- Kök adresi komut içine `cd` diye yazılmaz.
- `-k` artık yalnızca `--kok` aliasıdır; derleme-yok değildir.
- Derleme-yok için `-d` kullanılır.

## Örnek

```powershell
cd C:\Users\mete\Downloads\1\UXMv33
.\bellek_test.ps1
.\tum_test.ps1 -d -n 100
.\stage21_placeholder_test.ps1 -d
.\placeholder_kapi.ps1
```

## Release yorumu

Tüm testler geçerse ve placeholder kapısı temizse, reserved alanlar hariç bu sürüm release-candidate sayılır.
Reserved alanlar daha sonraya ayrılmışsa blocker değildir; ama kılavuzda açıkça RESERVED yazmalıdır.
