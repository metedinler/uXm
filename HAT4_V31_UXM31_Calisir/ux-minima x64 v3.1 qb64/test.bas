# Test Dosyaları

Aşağıdaki dosyaları aynı klasöre koy.

## `test01_print_A.uxm`

```text id="6f1w91"
0+k65.
```

Beklenen çıktı:

```text id="sgcj45"
A
```

---

## `test02_string.uxm`

```text id="771hm2"
s1=0,{Merhaba UX-MINIMA V3.1\n}
p1
```

Beklenen çıktı:

```text id="xyuwfm"
Merhaba UX-MINIMA V3.1
```

---

## `test03_addressing.uxm`

```text id="70rhc7"
0(T:10)+k65
.(T:10)
0(T+1)+k66
.(T+1)
```

Beklenen çıktı:

```text id="c9pglv"
AB
```

---

## `test04_stack.uxm`

```text id="uoi5ni"
0+k65$
0+k66$
%.
%.
```

Beklenen çıktı:

```text id="e68flv"
BA
```

---

## `test05_meta_add.uxm`

```text id="5qsmfx"
>>
0(T-2)+k10
0(T-1)+k20
@20
@61
```

Beklenen çıktı:

```text id="2jw14b"
30
```

Açıklama: `>>` ile pointer 2. hücreye gider. Frame şöyle olur:

```text id="x8mwod"
(T-2)=tape[0]=10
(T-1)=tape[1]=20
(T)=tape[2]=çağrı merkezi
(T+1)=tape[3]=sonuç
```

`@20` toplar, `@61` sonucu decimal basar.

---

## `test06_macro.uxm`

```text id="kszlcm"
m128={0+k65.}
@128
```

Beklenen çıktı:

```text id="92u6dt"
A
```

---

## `test07_dynamic_meta.uxm`

```text id="so1fpd"
>>
0(T-2)+k6
0(T-1)+k7
0(T)+k22
@#
@61
```

Beklenen çıktı:

```text id="cc9m3f"
42
```

---

## `test08_newline.uxm`

```text id="iqdyym"
0+k65.
@5
0+k66.
```

Beklenen çıktı:

```text id="uwg6as"
A
B
```

---

## `test09_div_mod.uxm`

```text id="aqcq1v"
>>
0(T-2)+k20
0(T-1)+k6
@23
@61
@5
@24
@61
```

Beklenen çıktı:

```text id="2uecwd"
3
2
```

---

## `test10_sin.uxm`

```text id="kdv0k8"
>>
0(T-1)+k30
@40
@61
```

Byte modda ölçek 100 olduğu için beklenen yaklaşık çıktı:

```text id="hl3ad7"
50
```

---

# Build Sırası

## 1. Compiler’ı QB64 ile derle

```bat id="wzuvbu"
qb64pe -x uxm31_qb64_compiler.bas -o uxm31_compiler.exe
```

QB64PE komut satırın farklıysa IDE’den de derleyebilirsin.

## 2. `.uxm` dosyasından ASM üret

Örnek:

```bat id="9gxrno"
uxm31_compiler.exe
```

Program sorunca:

```text id="p2bo7j"
Kaynak .uxm dosyasi: test05_meta_add.uxm
ASM cikis dosyasi [otomatik]:
```

Boş geçersen:

```text id="2s2mjc"
test05_meta_add.uxm.asm
```

oluşur.

## 3. NASM ile obj üret

```bat id="8cmiuc"
nasm -f win64 test05_meta_add.uxm.asm -o test05_meta_add.obj
```

## 4. FreeBASIC runtime ile linkle

```bat id="bqnl0x"
fbc uxm31_runtime.bas test05_meta_add.obj -x test05_meta_add.exe
```

## 5. Çalıştır

```bat id="zflyu5"
test05_meta_add.exe
```

Beklenen:

```text id="8g35sg"
30
[UXM program finished]
```

# Tek Test İçin Önerilen Komut Dizisi

```bat id="9s5giv"
uxm31_compiler.exe
nasm -f win64 test01_print_A.uxm.asm -o test01_print_A.obj
fbc uxm31_runtime.bas test01_print_A.obj -x test01_print_A.exe
test01_print_A.exe
```

# Not

Bu sürüm artık gerçek V3.1 iskeletidir ama henüz şu parçalar yok:

```text id="vi7ahg"
- JSON trace yok
- UIR dosyası dışarı yazılmıyor
- Pattern optimizer yok
- Pragma parser yok
- Native macro call stack yok; macro şu an inline genişliyor
- Safe/Wild mode parser ayarı yok
```

Ama şu anki çekirdek çalıştırma zinciri hazır:

```text id="dpyf93"
UXM kaynak -> QB64 compiler -> x64 NASM ASM -> OBJ -> FreeBASIC runtime ile EXE
```
