# Bölüm 12 — ASM, OBJ, JSON, CSV ve Rapor Dosyaları

UXM compiler yalnızca `.exe` üretmez; derleme ve test sürecinde çok sayıda ara dosya üretir. Bu dosyaları anlamak, compiler geliştiren biri için çok önemlidir.

## ASM dosyası

`.asm` dosyası NASM syntax’ına yakın x64 assembly metnidir. Codegen katmanı UXM komutlarını buraya çevirir. Örnek olarak `+` komutu aktif tape hücresini artıran bir instruction dizisine dönüşür; `@N` servis çağrısı runtime’daki meta dispatch fonksiyonuna çağrı üretir.

ASM dosyasında şunlar bulunabilir:

```text
section .data
section .bss
section .text
global main
call ux_meta_call_ex
```

## OBJ dosyası

`.obj`, NASM’in assembly dosyasından ürettiği object dosyasıdır. İnsan tarafından okunmaz; linker tarafından kullanılır. FreeBASIC runtime ve UXM runtime sembolleriyle bağlanınca `.exe` oluşur.

## JSON dosyası

JSON dosyaları test/diagnostic/trace gibi yapılandırılmış raporlar için kullanılır. Örneğin bir test koşusunun toplam kaç test koştuğu, kaçının geçtiği, hangi manifestin kullanıldığı JSON olarak saklanabilir. Bu, otomasyon için daha kullanışlıdır.

## CSV dosyası

CSV dosyaları servis tablosu ve test sonuçları için kullanılır. Test CSV’sinde genellikle şu alanlar olur:

```text
test_path,status,mode,expected,actual,seconds,exit_code
```

Hızlı tarama aracı bu CSV’yi okuyup yalnız hatalı testleri seçer. Böylece 1000 testi tekrar koşmak yerine 37 veya 83 tekil hatalı test tekrar çalıştırılır.

## RAPOR.md

`RAPOR.md` insan için okunur. Terminalde `rapor_goster.bat` ile gösterilir. Bu raporda toplam test, başarılı test, uyuşmazlık, build fail ve skipped sayısı bulunur.

## Artifact üretme akışı

```text
.uxm -> .asm -> .obj -> .exe -> stdout -> .csv -> RAPOR.md / JSON
```

Bu zincirde hata nerede çıktıysa çözüm de ona göre yapılır. `.asm` oluşmuyorsa compiler/codegen; `.obj` oluşmuyorsa NASM; `.exe` oluşmuyorsa link; çıktı yanlışsa runtime/servis/test beklenen değeri incelenir.
