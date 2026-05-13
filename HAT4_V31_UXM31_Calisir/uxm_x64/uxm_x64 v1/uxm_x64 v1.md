Daha onceki versiyonu direkt freebasic ile yazmisttim. Bu sefer qb64 ile yazdim. Ama AB64 ile yazarken compilerin ilk tasarlandigi haline yakin olmasini diledim. cunku ileride bu sekildeki data pattern yapisina kendi acimdan yeni bilgi eklemek daha kolay olur. Ayrica onceki derleyici ile sonraki derleyiciler arasinda bir ara versiyon olmasini diledim.

QB64’e çevirirken FreeBASIC’e özgü ULongInt, Cdecl, bazı tip adları ve IIF gibi alışkanlıkları bıraktım. Bu dosya QB64 ile çalışan compiler olacak; yine .uxm okuyup Windows x64 NASM .asm üretecek. Runtime/link tarafını ayrı tutmak daha doğru, çünkü QB64’in NASM obj ile doğrudan link modeli FreeBASIC kadar rahat değil.

Aşağıdaki dosya QB64 ile yazılmış UXM-64K compiler sürümüdür. Mantık aynı: .uxm/.txt okur, 26 komutluk UXM dilini işler, 64 KB belleği tape + stack + data olarak ayırır ve Windows x64 NASM .asm çıktısı üretir. İlk paylaştığın UX-MINIMA’daki pattern tabanlı derleyici fikrini bu sürüme taşıdım

Istediğim model, önceki 6502 örneğindeki gibi:

```text
PatternData:
DATA 256
DATA "[-]", "x64 ASM karşılığı"
DATA "[->+<]", "x64 ASM karşılığı"
...
```

Yani **pattern tablosu DATA kısmında duracak**, compiler bu patternleri okuyacak, UXM token dizisinde eşleşme arayacak ve eşleşirse karşısındaki **x64 NASM kod şablonunu** basacak.

Senin istediğin **data-driven industrial compiler** yapısı değildi. Bu yeni dosyada onu düzelttim.

Hazır dosyalar:

[QB64 UXM-64K V3 data-driven compiler](sandbox:/mnt/data/uxm64_v3_data_driven_qb64.bas)

[FreeBASIC runtime](sandbox:/mnt/data/uxm64_runtime.bas)

QB64 ile yazilan derleyinicin adini daha kolay sekilde kullanmak amaciyla `uxm64_v3.bas` olarak aslindan kopyalayip adini degistirdim.
derleyicinin v3 versiyonunda asagidaki komut setini kullaniyoruz:

# Komut Seti
```
' No COMMAND SET:   Anlami
'   1  >            saga git
'   2  <            sola git
'   3  +            artir
'   4  -            azalt
'   5  0            sifirla
'   6  .            karakter bas
'   7  ,            karakter oku
'   8  [            dongu/kosul basi
'   9  ]            dongu/kosul sonu
'   10 $            push
'   11 %            pop
'   12 ?            esit mi
'   13 !            buyuk mu
'   14 ;            kucuk mu
'   15 &            AND
'   16 |            OR
'   17 ^            XOR
'   18 ~            NOT
'   19 @            meta/runtime cagri
'   20 sN           string tanimla
'   21 pN           string bas
'   22 kN           tekrar makrosu
'   23 #            yorum
'   24 :            label/ayirici
'   25 {            SHL / sola kaydir / ikiyle carp
'   26 }            SHR / saga kaydir / ikiye bol
```

Bu versiyonda Hafiza yapsisi 64 KB olarak dusunuldu. 64 KB bellek, tape + stack + data olarak kullanilacak. 

' MEMORY MODEL:
'   Total UXM memory = 64 KB
'   ux_mem = tape + stack + data

Bu yeni compiler’da:

```text
1. 26 komutluk UXM V3 komut ailesi var.
2. 64 KB bellek tape + stack + data olarak ayarlanıyor.
3. Patternler DATA kısmında yazıyor.
4. Pattern sayısı tam 256.
5. Patternler doğrudan x64 NASM şablonuna çevriliyor.
6. Şablonlarda {CELL0}, {CELL+1}, {REG}, {PTRCHECK} gibi yer tutucular var.
7. Compiler bu yer tutucuları seçilen byte/word/dword hücre tipine göre gerçek x64 operandına çeviriyor.
8. Girintileme korundu, ama satır aralarında boş satır bırakmadım.
```

Örnek DATA mantığı artık böyle:

```basic
PatternData:
DATA 256
DATA "[-]","{CHECK0}|mov {CELL0}, 0"
DATA "[->+<]","{CHECK+1}|mov {REG}, {CELL0}|add {CELL+1}, {REG}|mov {CELL0}, 0"
DATA "++","{CHECK0}|add {CELL0}, 2"
DATA ">>>","add rbx, 3|{PTRCHECK}"
```

Bunlar çıktı ASM’de örneğin byte hücre için şöyle açılır:

```asm
mov al, byte [r12 + rbx]
add byte [r12 + rbx + 1], al
mov byte [r12 + rbx], 0
```

Derleme akışı:

```bash
qb64pe uxm64_v3_data_driven_qb64.bas
uxm64_v3_data_driven_qb64.exe
nasm -f win64 test.asm -o build.obj
fbc uxm64_runtime.bas build.obj -x program.exe
program.exe
```

Test dosyası `test.uxm`:

```text
# test
s1=0,{UXM-64K V3 data-driven compiler calisti}
s2=100,{A harfi: }
s3=200,{Esitlik dogru}
s4=300,{AND sonucu: }
p1
0+++++@
p2
+k65.
0+++++@
+k65$0+k65?[
p3
0
]
0+++++@
p4
+k65$0+k127&.
0+++++@
```

Bu sefer yapı, senin verdiğin 6502 compiler örneğinin mantığına benziyor; fark şu: hedef artık **6502 ASM değil, Windows x64 NASM**.
