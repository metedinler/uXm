



````markdown
# Programcı Adayının Cep Kitabı
## UX-MINIMA x64 V3 Compiler için pratik, düşünsel ve teknik giriş kitabı
### Bölüm 1/4 — Dilin Mantığı, Komut Seti, Bellek Modeli ve Programcının Düşünme Biçimi

---

## 1. Bu kitap kimin için yazıldı?

Bu cep kitabı, BASIC veya Python gibi daha okunabilir dillerle programlamayı öğrenmiş, fakat Brainfuck benzeri düşük seviyeli sembolik dillere merak salmış 17 yaş civarında bir programcı adayı için yazılmıştır. Bu kişi değişken, döngü, koşul, ekrana yazma, klavyeden giriş alma, string, liste veya dizi gibi kavramları az çok biliyor olabilir. Fakat UX-MINIMA x64 V3 gibi bir dilde bu kavramların çoğu doğrudan hazır kelimelerle verilmez. Bu dilde `IF`, `THEN`, `FOR`, `WHILE`, `PRINT`, `DIM`, `LET`, `INPUT`, `FUNCTION` gibi kelimeler yoktur. Bunun yerine daha çıplak, daha atomik, daha işlemciye yakın komutlar vardır.

UX-MINIMA x64 V3’ü öğrenmek, sadece yeni bir oyuncak dil öğrenmek değildir. Asıl amaç, bilgisayarın en temel davranışlarını çıplak gözle görmektir. Bellek nasıl düşünülür, pointer nasıl hareket eder, bir hücre nasıl değişken gibi kullanılır, döngü nasıl kurulur, koşul nasıl taklit edilir, stack ne işe yarar, data alanı neden ayrı tutulur, string aslında bellekte nasıl saklanır, bir compiler sembolik komutları nasıl assembler koduna çevirir; bu kitap bu soruların cevabını adım adım verir.

Bu kitabın hedefi, okuyucunun “ben UX-MINIMA ile büyük uygulamalar yazacağım” demesinden çok, “ben programlamanın temel taşlarını anladım; artık compiler, interpreter, assembly, bellek modeli ve düşük seviyeli tasarım bana yabancı değil” diyebilmesidir.

---

## 2. UX-MINIMA x64 V3 nedir?

UX-MINIMA x64 V3, tape tabanlı, stack destekli, data alanı olan, sembolik komutlarla çalışan ve Windows x64 NASM assembler çıktısı üretecek şekilde tasarlanmış deneysel bir mini compiler dilidir.

Bu tanımı parçalara ayıralım.

“Tape tabanlı” demek, programın uzun bir hücre dizisi üzerinde çalışması demektir. Bu hücre dizisini eski bir hesap makinesi şeridi, laboratuvarda yan yana dizilmiş tüpler, DNA dizisi, protein zinciri, kimyasal madde miktarları veya bellek kutuları gibi düşünebilirsin. Programın bir pointer’ı vardır. Pointer hangi hücrede duruyorsa, komutlar çoğunlukla o hücre üzerinde işlem yapar.

“Stack destekli” demek, programın geçici değerleri son giren ilk çıkar mantığıyla saklayabileceği ayrı bir alanı olduğu anlamına gelir. Bu stack, işlemcinin gerçek donanım stack’i değildir. UX-MINIMA’nın kendi kullanıcı stack alanıdır. `$` komutu aktif hücredeki değeri stack’e atar. `%` komutu stack’ten son değeri alıp aktif hücreye yazar.

“Data alanı olan” demek, stringler ve ileride başka sabit/veri blokları için tape’ten ayrı bir bellek bölgesi ayrıldığı anlamına gelir. Örneğin `s1=0,{Merhaba}` yazdığında bu string tape’e değil, data alanına yerleştirilir. `p1` komutu bu stringi data alanından okuyup ekrana basar.

“Sembolik komutlarla çalışan” demek, dilin komutlarının kelime değil işaretlerden oluşmasıdır. Örneğin `>` sağa git, `<` sola git, `+` artır, `-` azalt, `[` döngü başı, `]` döngü sonudur.

“Windows x64 NASM assembler çıktısı üretir” demek, bu dilin yorumlanmak yerine derlenebilecek şekilde tasarlandığı anlamına gelir. Compiler `.uxm` kaynak dosyasını okur, komutları ve patternleri analiz eder, sonra `.asm` dosyası üretir. Bu `.asm` dosyası NASM ile `.obj` dosyasına çevrilir ve FreeBASIC runtime ile linklenerek `.exe` haline gelir.

---

## 3. Neden böyle garip bir dil tasarlandı?

Normal bir programlama dilinde şöyle yazarsın:

```basic
PRINT "Merhaba"
````

Python’da şöyle yazarsın:

```python
print("Merhaba")
```

UX-MINIMA’da ise şöyle yazarsın:

```text
s1=0,{Merhaba}
p1
```

İlk bakışta bu daha zor görünür. Fakat UX-MINIMA’nın amacı kolaylık değil, yapının nasıl çalıştığını göstermektir. Burada stringin bir yerde saklandığını, sonra bir komutla o stringin data alanından okunup ekrana basıldığını açıkça hissedersin.

Normal bir dilde şöyle yazarsın:

```basic
A = 10
B = 0
B = B + A
A = 0
```

UX-MINIMA’da bunun düşük seviyeli karşılığı şu fikirdir:

```text
+k10[->+<]
```

Burada `tape[0]` içinde 10 vardır. `[->+<]` patterni, aktif hücredeki değeri sağdaki hücreye taşıyıp aktif hücreyi sıfırlar. Yani bir tür “madde transferi”, “değer taşıma”, “A’dan B’ye aktarım” yapılır.

Bu dilin garip görünmesinin nedeni, programcının alıştığı isimli değişken dünyasından çıkarılıp, bellek hücreleriyle doğrudan yüzleştirilmesidir. İşte eğitim değeri burada başlar.

---

## 4. UX-MINIMA x64 V3 compiler ailesi

Bu dil için birkaç farklı compiler tasarım yolu denendi. Bunları bilmek önemlidir, çünkü UX-MINIMA sadece bir dil değil, aynı zamanda compiler tasarımı deneyi olarak da düşünülmelidir.

İlk yaklaşım, sembolik komutları tek tek okuyup doğrudan x64 assembler satırları üretmekti. Bu yöntem basittir. `+` görünce `inc byte [r12 + rbx]`, `>` görünce `inc rbx`, `.` görünce `ux_putc` çağrısı üretilebilir. Fakat bu yöntem optimizasyon bakımından zayıftır. Çünkü `+++++++++++++++++++++++++++++++++` gibi uzun tekrarları tek tek işlemek gereksiz ASM şişmesine yol açar.

İkinci yaklaşım, “pattern → action → emitter” modeliydi. Bu modelde pattern tablosu bir işlem türüne bağlanır. Örneğin `[->+<]` patterni `MOVE_ADD_RIGHT_CLEAR` action’ına bağlanır. Sonra emitter bu action’a göre seçilen hücre tipine uygun ASM üretir. Bu modern compiler mantığına yakındır. Ancak önceki 6502 UX-MINIMA tasarımındaki gibi doğrudan DATA tablosu üzerinden pattern ve karşılığı olan assembler şablonu yazma fikrine tam uymaz.

Üçüncü ve son yaklaşım, bu cep kitabında esas alınan **data-driven pattern compiler** yaklaşımıdır. Bu modelde patternler DATA alanında saklanır. Her patternin karşısında x64 NASM şablonu bulunur. Compiler kaynak kodda bu patterni görürse ilgili ASM şablonunu açar. Bu, önceki 6502 compiler fikrine daha çok benzer; tek fark hedef artık Commodore 64 / 6502 değil, Windows x64 NASM’dir.

Bu yüzden UX-MINIMA x64 V3 için üç önemli kavramı ayırmak gerekir: dil komutları, pattern bankası ve runtime. Dil komutları kullanıcının yazdığı sembollerdir. Pattern bankası compiler’ın bu sembol dizilerini daha kısa ve optimize ASM’ye çevirmek için kullandığı tablodur. Runtime ise ekrana yazma, karakter alma, meta servis, hata mesajları gibi işleri FreeBASIC tarafında sağlayan yardımcı koddur.

---

## 5. Komut seti: 26 temel yapı taşı

UX-MINIMA x64 V3’ün son tasarımında 26 temel komut veya direktif vardır. Bunların bazıları doğrudan tek karakter komuttur, bazıları ise compiler direktifi gibi davranır.

```text
1  >     sağa git
2  <     sola git
3  +     artır
4  -     azalt
5  0     sıfırla
6  .     karakter bas
7  ,     karakter oku
8  [     döngü/koşul başı
9  ]     döngü/koşul sonu
10 $     push
11 %     pop
12 ?     eşit mi
13 !     büyük mü
14 ;     küçük mü
15 &     AND
16 |     OR
17 ^     XOR
18 ~     NOT
19 @     meta/runtime çağrı
20 sN    string tanımla
21 pN    string bas
22 kN    tekrar makrosu
23 #     yorum/satır açıklaması
24 :     gelecekte label veya mini ayırıcı
25 {     SHL / sola kaydır / ikiyle çarp
26 }     SHR / sağa kaydır / ikiye böl
```

Bu 26 komut, küçük bir işlemci komut seti gibi düşünülebilir. Burada veri hareketi vardır, aritmetik vardır, bitwise işlem vardır, karşılaştırma vardır, döngü vardır, stack vardır, giriş/çıkış vardır, runtime çağrısı vardır, string/data sistemi vardır.

Başta Brainfuck 8 komutlu gibi görünür. Fakat gerçek programlamaya yaklaştıkça, ister istemez bu komut ailesi genişler. Çünkü programlama sonunda hep aynı temel sorunlara döner: veri nerede duruyor, nasıl değiştirilecek, nasıl karşılaştırılacak, ne zaman döngüye girilecek, ne zaman ekrana yazılacak, geçici değer nerede saklanacak?

---

## 6. Tape sistemi: değişken isimleri yok, hücreler var

UX-MINIMA’da klasik anlamda `x`, `y`, `toplam`, `sayac`, `isim` gibi değişkenler yoktur. Bunun yerine tape hücreleri vardır.

Başlangıçta pointer `tape[0]` üzerindedir.

```text
tape[0] tape[1] tape[2] tape[3] tape[4]
   ^
 pointer
```

`+` komutu aktif hücreyi artırır. Eğer başlangıçta her hücre 0 ise:

```text
+
```

sonra durum şudur:

```text
tape[0] = 1
pointer = 0
```

`>+` yazarsan pointer sağa gider ve sağdaki hücre artırılır:

```text
>+
```

sonra durum şudur:

```text
tape[0] = 0
tape[1] = 1
pointer = 1
```

Bu düşünme biçimi BASIC veya Python’dan çok farklıdır. Python’da şöyle yazarsın:

```python
a = 10
b = 20
```

UX-MINIMA’da ise aynı şeyi şöyle düşünürsün:

```text
tape[0] = a gibi kullanılacak
tape[1] = b gibi kullanılacak
```

Kod olarak:

```text
+k10>+k20
```

Bu kodda `+k10`, `+` komutunu 10 kez tekrarlar. `>` pointer’ı `tape[1]` hücresine taşır. `+k20` de orayı 20 yapar.

Burada önemli olan şudur: Bir hücrenin değişken mi, sabit mi, sayaç mı, geçici değer mi, kimyasal madde miktarı mı, DNA bazı mı, protein aminoasit kodu mu olduğu compiler tarafından bilinmez. Buna programcı karar verir. Yani bellek hücrelerinin anlamı programcının zihinsel tasarımına aittir.

---

## 7. Her bellek bloğu bir değişken olabilir

UX-MINIMA’da her hücre bir değişken gibi düşünülebilir. Ama bu değişkenin adı yoktur. Adı, programcının defterinde veya zihninde vardır.

Örneğin bir program tasarlarken önce şöyle bir plan yapmalısın:

```text
tape[0] = sayaç
tape[1] = basılacak karakter
tape[2] = geçici değer
tape[3] = karşılaştırma sonucu
```

Sonra kodunu bu plana göre yazarsın.

Mesela 10 tane yıldız basmak için şöyle düşünebilirsin:

```text
tape[0] = kaç tane yıldız basılacak
tape[1] = yıldız karakterinin ASCII değeri
```

Kod:

```text
+k10>+k42<[>.<-]
```

Açıklama:

```text
+k10     tape[0] = 10
>        tape[1]'e git
+k42     tape[1] = 42, ASCII '*'
<        tape[0]'a dön
[        tape[0] sıfır değilken döngüye gir
>        tape[1]'e git
.        karakter bas
<        tape[0]'a dön
-        sayaç azalt
]        döngü başına dön
```

Çıktı:

```text
**********
```

Bu örnek, UX-MINIMA düşüncesinin temelidir. Bir hücre sayaçtır. Bir hücre karakterdir. Döngü aktif hücre üzerinden çalışır. Programcı, pointer’ın nerede olduğunu her adımda bilmek zorundadır.

---

## 8. Pointer kullanımı: nerede durduğunu unutma

UX-MINIMA’da en büyük hata kaynağı pointer’ı unutmaktır. Python’da `x = x + 1` yazarsın ve hangi değişkeni değiştirdiğin bellidir. UX-MINIMA’da ise `+` sadece aktif hücreyi değiştirir. Aktif hücrenin neresi olduğunu sen bilmelisin.

Örneğin:

```text
+k65>+k66.
```

Bu kod `B` harfini basar, çünkü `.` çalıştığında pointer `tape[1]` üzerindedir.

Eğer `A` basmak istiyorsan pointer’ı geri almalısın:

```text
+k65>+k66<.
```

Şimdi `.` komutu `tape[0]` değerini basar. `tape[0] = 65` olduğu için çıktı `A` olur.

Bu yüzden UX-MINIMA programcısı her satırın sonunda zihninde şunu sormalıdır: “Pointer şu anda nerede?”

İyi bir UX-MINIMA programcısı koddan önce küçük bellek haritası yazar. Örneğin:

```text
# Bellek planı
# tape[0] = ana sayaç
# tape[1] = karakter
# tape[2] = geçici hücre
```

Sonra kod:

```text
+k5>+k65<[>.<-]
```

Böylece kod daha anlaşılır hale gelir.

---

## 9. Kısaltılmış komut kullanımı: kN repeat macro

UX-MINIMA’da uzun uzun `+` yazmak yerine repeat macro kullanılabilir.

```text
+k65
```

bu anlama gelir:

```text
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
```

Aynı şey diğer komutlarda da geçerlidir:

```text
>k10
<k4
-k7
$k3
```

Bu makro lexer aşamasında açılır. Yani compiler bunu doğrudan token dizisine çevirir. Fakat pattern optimizer devreye girerse bu tekrarlar tek tek ASM üretmek yerine daha kısa ASM’ye çevrilebilir.

Örneğin:

```text
+k65.
```

şu mantığa iner:

```asm
add byte [r12 + rbx], 65
movzx ecx, byte [r12 + rbx]
call ux_putc
```

Bu sayede hem kaynak kod okunabilir olur hem de üretilen ASM gereksiz yere büyümez.

---

## 10. String tanımlama ve ekrana yazma

UX-MINIMA’da stringler data alanına yerleştirilir. String tanımlamak için `sN=başlangıç,{metin}` biçimi kullanılır. Burada `N` string numarasıdır. Başlangıç değeri data alanındaki hücre numarasıdır.

Örnek:

```text
s1=0,{Merhaba}
p1
```

Bu program `Merhaba` yazar.

Burada `s1=0,{Merhaba}` komutu stringi data alanının 0. hücresinden itibaren yerleştirir. `p1` ise string 1’i basar.

Birden fazla string yazılabilir:

```text
s1=0,{UX-MINIMA V3}
s2=100,{x64 NASM cikti uretir}
p1
0+++++@
p2
```

Burada `0+++++@` meta servis 5’i çağırır. Bu runtime’da yeni satır basmak için kullanılır.

Çıktı:

```text
UX-MINIMA V3
x64 NASM cikti uretir
```

Stringlerin data alanında tutulması önemlidir. Tape alanı aktif işlem alanıdır. Data alanı ise daha çok sabit metin, tablo, ileride model verisi, dizi veya veri bankası gibi düşünülebilir.

---

## 11. Meta komut kullanımı

`@` komutu, aktif hücredeki değeri runtime servis numarası gibi kullanır. Yani `@`, UX-MINIMA’nın dış dünyaya açılan kapısıdır.

Örneğin:

```text
0+++++@
```

şu işlemi yapar:

```text
0       aktif hücreyi sıfırla
+++++   aktif hücreyi 5 yap
@       meta servis 5 çağır
```

Runtime tarafında meta servis 5 yeni satır basar.

Genel meta servis tablosu şu şekilde düşünülebilir:

```text
0 = boş işlem
1 = ekranı temizle
2 = imleci başa al
3 = rastgele değer üret
4 = zaman/timer değeri üret
5 = yeni satır bas
6 = UXM meta mesajı bas
7 = test değeri döndür
8 = test değeri döndür
```

Örnek ekran temizleme:

```text
0+@
```

Çünkü aktif hücre 1 yapılır ve meta servis 1 çağrılır.

Örnek rastgele değer:

```text
0+++@.
```

Burada meta servis 3 rastgele bir değer döndürür. Sonra `.` bu değeri karakter olarak basar. Bu her zaman okunabilir karakter olmayabilir, çünkü rastgele değer 0–255 arasında olabilir.


## EK BOLUM — UX-MAT V1 HIZLI CEP NOTU

UX-MAT V1, Data alaninda blok tabanli matris saklama ve host-hizlandiricili matris islemleri sunar.

Hizli ozet:

- Matris macro/meta araligi: `m160..m193` / `@!160..@!193`
- V1 temel cagri grubu: `@160..@176`
- Header baslangici: `D:BASE+0 = 77`, `D:BASE+1 = 1`
- Veri baslangici: `D:BASE+16`
- Ilk parser direktifleri: `#matrix`, `#matrix-signed`, `#matrix-fixed`, `#identity`, `#zeros`, `#ones`

Minimum frame (genis):

- `T-4 = destination/matrix base`
- `T-3 = A base/row/rows`
- `T-2 = B base/col/cols`
- `T-1 = param1/value/type`
- `T   = param2/scale`
- `T+1 = result/status`

Pratik kural:

- Matris testlerinde `#cell dword` ve `#compare signed` tercih et.

---

## 12. Stack kullanımı

Stack, geçici değer saklamak için kullanılır. UX-MINIMA’da stack komutları şunlardır:

```text
$ = aktif hücreyi stack'e push et
% = stack'ten pop et ve aktif hücreye yaz
```

Örnek:

```text
+k65$>%.
```

Açıklama:

```text
+k65   tape[0] = 65
$      65 stack'e atılır
>      tape[1]'e geçilir
%      stack'ten 65 alınır ve tape[1]'e yazılır
.      tape[1] karakter olarak basılır
```

Çıktı:

```text
A
```

Stack son giren ilk çıkar mantığıyla çalışır. Buna LIFO denir.

Örnek:

```text
+k65$0+k66$0%.0%.
```

Burada önce 65, sonra 66 stack’e atılır. İlk pop 66’yı verir, ikinci pop 65’i verir. Çıktı `BA` olur.

Stack kullanırken kurallar şunlardır: Stack boşken `%`, `?`, `!`, `;`, `&`, `|`, `^` gibi stack’ten değer bekleyen komutları kullanma. Stack kapasitesini aşacak kadar `$` kullanma. Hangi değeri stack’e attığını ve hangi sırayla geri alacağını mutlaka düşün. Stack görünmez bir alan olduğu için hata yapmak kolaydır.

---

## 13. Karşılaştırma ve IF düşüncesi

UX-MINIMA’da `IF THEN` kelimesi yoktur. Ama koşul kurmak mümkündür. Bunun için karşılaştırma komutları ve döngü bloğu birlikte kullanılır.

Karşılaştırma komutları stack ile çalışır:

```text
? = stackTop == current
! = stackTop > current
; = stackTop < current
```

Sonuç aktif hücreye yazılır:

```text
1 = doğru
0 = yanlış
```

Örnek:

```text
+k65$0+k65?
```

Bu, “65 eşit mi 65?” anlamına gelir. Sonuç 1 olur.

Bunu koşullu blok gibi kullanmak için `[` ve `]` kullanılır:

```text
s1=0,{Esitlik dogru}
+k65$0+k65?[
p1
0
]
```

Burada karşılaştırma sonucu 1 ise blok çalışır. Blok içinde `p1` stringi basılır. Sonra `0` ile aktif hücre sıfırlanır. Bu önemlidir; çünkü `[` `]` aslında döngüdür. Eğer blok sonunda flag sıfırlanmazsa sonsuz döngü oluşabilir.

Bu şuna benzer:

```basic
IF 65 = 65 THEN
    PRINT "Esitlik dogru"
END IF
```

Ama UX-MINIMA’da bunu hücre ve flag mantığıyla sen kurarsın.

---

## 14. Döngü tasarımı

UX-MINIMA’da döngü şu yapıyla kurulur:

```text
[
...
]
```

Bu yapı aktif hücre sıfır değilse bloğa girer. Blok sonunda `]` görülünce başa döner. Eğer aktif hücre sıfırsa döngü biter.

En klasik döngü sayaç döngüsüdür:

```text
+k5[
-
]
```

Bu kod aktif hücreyi 5 yapar, sonra her turda 1 azaltır. Fakat bu döngü hiçbir şey basmaz. Daha kullanışlı bir örnek:

```text
+k5>+k42<[>.<-]
```

Bu 5 tane yıldız basar.

Döngü tasarlarken şu üç soruyu sormalısın: Döngünün sayaç hücresi nerede? Döngü içinde pointer başka hücrelere gidiyorsa, döngü sonunda tekrar sayaç hücresine dönüyor mu? Döngü sayacı her turda azalıyor mu veya eninde sonunda sıfır oluyor mu?

Eğer bu üç sorudan birini unutursan, döngü sonsuza gidebilir veya yanlış hücreyi azaltabilir.

---

## 15. Bitwise işlemler

UX-MINIMA V3’te BASIC tarzı bitwise işlemler de vardır:

```text
& = AND
| = OR
^ = XOR
~ = NOT
```

İkili bitwise işlemler stack ile çalışır. Önce sol değer stack’e atılır, sonra sağ değer aktif hücrede tutulur, sonra işlem yapılır.

Örnek:

```text
+k65$0+k127&.
```

Burada 65 ile 127 AND işlemine sokulur. Sonuç 65 olur. 65 ASCII’de `A` olduğu için çıktı `A` olur.

XOR örneği:

```text
+k65$0+k1^.
```

65 XOR 1 sonucu 64 olur. ASCII 64 `@` karakteridir.

NOT işlemi tek hücre üzerinde çalışır:

```text
+k0~.
```

Fakat NOT işlemi tüm bitleri terslediği için byte hücrede 0 değeri 255 olur. 255 görünür bir ASCII karakter olmayabilir. Bu yüzden NOT genellikle karakter basmak için değil, bit maskesi işlemleri için düşünülmelidir.

---

## 16. Shift işlemleri

Shift komutları şunlardır:

```text
{ = sola kaydır / SHL / ikiyle çarp
} = sağa kaydır / SHR / ikiye böl
```

Örnek:

```text
+k32{.
```

32 sola kaydırılır, yani 64 olur. ASCII 64 `@` olduğu için çıktı `@` olur.

Sağa kaydırma:

```text
+k130}.
```

130 sağa kaydırılır, yani 65 olur. ASCII 65 `A` olduğu için çıktı `A` olur.

Bu işlemler bilimsel hesap için değil, düşük seviyeli bit manipülasyonu için düşünülmelidir. Byte, word veya dword hücre tipine göre davranış değişebilir. Overflow check açıksa sola kaydırma taşmaya neden olabilir.

---

## 17. Programcının yeni düşünme biçimi

BASIC veya Python bilen biri genellikle isimli değişkenlerle düşünür. `x`, `y`, `toplam`, `liste`, `metin` gibi isimler kullanır. UX-MINIMA’da bu rahatlık yoktur. Burada programcı, bellek haritası çıkarmalıdır.

İyi bir UX-MINIMA programı yazmaya başlamadan önce şu tarz bir plan yapılmalıdır:

```text
# tape[0] = ana sayaç
# tape[1] = karakter
# tape[2] = geçici değer
# tape[3] = koşul sonucu
# data[0] = başlık stringi
# data[100] = hata mesajı
# stack = karşılaştırma ve geçici saklama
```

Bu plan olmadan yazılan UX-MINIMA kodu çok hızlı karışır. Programcının kafasında pointer’ın nerede olduğu, hangi hücrenin ne anlama geldiği, stack’te neyin durduğu ve döngü sonunda hangi hücreye dönüldüğü sürekli canlı kalmalıdır.

Bu dilin asıl öğretici yanı da budur. UX-MINIMA seni programın görünen yüzünden alıp, belleğin ve işlemin çıplak yapısına götürür.

---

## 18. Bölüm 1 özeti

Bu bölümde UX-MINIMA x64 V3’ün ne olduğunu, neden tasarlandığını, hangi compiler yaklaşımlarından geçtiğini, 26 komutluk son komut ailesini, tape modelini, pointer düşüncesini, string/data alanını, meta komutları, stack mantığını, karşılaştırma ile IF kurmayı, döngü tasarımını, bitwise ve shift işlemlerini gördük.

Bu noktada okuyucunun şunu anlaması gerekir: UX-MINIMA’da değişken yok gibi görünür ama aslında her hücre değişken olabilir. IF yok gibi görünür ama karşılaştırma ve döngüyle kurulabilir. PRINT yok gibi görünür ama `.` ve `pN` ile ekrana yazılabilir. FOR yok gibi görünür ama sayaç hücresiyle döngü kurulabilir. Dizi yok gibi görünür ama tape zaten dizinin en çıplak halidir.

Bundan sonraki bölümde, diğer dillerde hazır gelen yapıların UX-MINIMA’da nasıl kurulacağını ayrıntılı inceleyeceğiz: değişken, sabit, dizi, sayaç, FOR döngüsü, WHILE döngüsü, IF-ELSE benzeri yapı, input/output düzeni, string kullanımı, stack tabanlı hesaplama ve gerçek küçük program örnekleri.

**Bölüm 1/4 burada bitti. Devam etmek için “devam” yaz.**

```
```


````markdown id="s8l4wd"
## Bölüm 2/4 — Diğer Dillerdeki Yapıları UX-MINIMA ile Kurmak

---

## 19. BASIC ve Python bilen biri için ilk kırılma noktası

BASIC veya Python bilen bir programcı, genellikle programı şu kelimelerle düşünür: değişken, değer atama, ekrana yazma, klavyeden giriş alma, koşul, döngü, fonksiyon, liste, dizi, string ve dosya. UX-MINIMA’da bu kelimelerin çoğu doğrudan yoktur. Fakat bu yapıların neredeyse tamamı daha düşük seviyeli parçalarla kurulabilir.

BASIC’te şöyle yazarsın:

```basic
A = 10
B = 20
C = A + B
PRINT C
````

Python’da şöyle yazarsın:

```python id="md8tzr"
a = 10
b = 20
c = a + b
print(c)
```

UX-MINIMA’da ise şu soruları sormalısın:

```text id="potzqx"
A hangi tape hücresinde duracak?
B hangi tape hücresinde duracak?
C hangi tape hücresinde duracak?
Toplama doğrudan mı yapılacak, yoksa değer taşıma ile mi kurulacak?
Sonuç karakter olarak mı basılacak, bar grafik olarak mı gösterilecek, yoksa string içinde mi anlatılacak?
```

Bu yüzden UX-MINIMA’da program yazmak, sadece komut yazmak değil, önce bellek tasarlamaktır. Bu dilde iyi program yazmanın ilk kuralı şudur: Koddan önce bellek haritası yapılır.

---

## 20. Değişken nasıl kurulur?

UX-MINIMA’da değişken adı yoktur. Ama her tape hücresi değişken gibi kullanılabilir. Örneğin şöyle bir plan yapabilirsin:

```text id="a8m3hl"
tape[0] = A
tape[1] = B
tape[2] = C
```

A değişkenine 10 vermek için:

```text id="rn3t9v"
+k10
```

B değişkenine 20 vermek için pointer’ı sağa taşırsın:

```text id="b2ubaz"
>+k20
```

Bunları birlikte yazarsan:

```text id="yj50kc"
+k10>+k20
```

Bu koddan sonra:

```text id="hh1djj"
tape[0] = 10
tape[1] = 20
pointer = 1
```

Burada çok önemli bir nokta var: Kodun sonunda pointer `tape[1]` üzerindedir. Eğer tekrar A üzerinde işlem yapacaksan `<` ile geri dönmelisin.

```text id="g4ezyr"
+k10>+k20<
```

Bu koddan sonra:

```text id="g0flac"
tape[0] = 10
tape[1] = 20
pointer = 0
```

BASIC’te değişken adını yazarak istediğin yere ulaşırsın. UX-MINIMA’da pointer’ı doğru hücreye götürmek zorundasın. Bu yüzden pointer hareketleri kodun en önemli parçasıdır.

---

## 21. Sabit nasıl düşünülür?

Sabit, program boyunca değişmeyeceğini varsaydığın hücredir. Fakat compiler bunu bilmez. Sabitlik, programcının disiplinidir.

Örneğin:

```text id="sf27wu"
tape[0] = sayaç
tape[1] = yıldız karakteri, sabit 42
```

Kod:

```text id="rfo7dr"
+k5>+k42<
```

Burada `tape[1]` içine 42 koyduk. 42 ASCII’de `*` karakteridir. Bu hücreyi program boyunca değiştirmezsek, onu sabit gibi kullanmış oluruz.

Ama UX-MINIMA bunu korumaz. Yanlışlıkla `>` ile oraya gidip `+` dersen, sabit bozulur. Bu yüzden yorum satırları önemlidir:

```text id="j57rkx"
# tape[0] = sayaç
# tape[1] = sabit yıldız karakteri, 42
+k5>+k42<
```

Bu dilde yorumlar sadece insana yardım eder. Compiler `#` sonrası satırı yok sayar.

---

## 22. Atama işlemi nasıl kurulur?

BASIC’te atama basittir:

```basic id="igzxeb"
A = 65
```

UX-MINIMA’da aktif hücreyi önce sıfırlayıp sonra istenen değeri eklersin:

```text id="s5htdq"
0+k65
```

Bu, aktif hücreyi 65 yapar. Eğer hücrede başlangıçta zaten 0 olduğundan eminsen `0` yazmadan da `+k65` kullanabilirsin. Ama güvenli yazım şudur:

```text id="bsxoqv"
0+k65
```

Çünkü aktif hücrenin içinde daha önce ne olduğunu bilmiyorsan, sadece `+k65` demek eski değerin üzerine 65 ekler. Bu da atama değil toplama olur.

Atama için kural:

```text id="cjg1c8"
önce 0
sonra +kN
```

Örnek:

```text id="z2c2w7"
0+k10
```

anlamı:

```text id="i8sf4p"
aktif hücre = 10
```

---

## 23. Toplama nasıl yapılır?

UX-MINIMA’da doğrudan “A + B sonucunu C’ye yaz” gibi bir komut yoktur. Ama değer taşıma patternleriyle bu işlem kurulabilir.

Basit taşıma patterni:

```text id="df5l56"
[->+<]
```

Bu pattern aktif hücredeki değeri sağdaki hücreye ekler ve aktif hücreyi sıfırlar.

Başlangıç:

```text id="pwifge"
tape[0] = 10
tape[1] = 20
pointer = 0
```

Kod:

```text id="zsb2d9"
[->+<]
```

Sonuç:

```text id="xc52gc"
tape[0] = 0
tape[1] = 30
pointer = 0
```

Yani A değeri B’ye eklenmiş olur. Ama A kaybolur. Bu çok önemlidir. Bu pattern “kopyalayarak toplama” değil, “taşıyarak toplama” yapar.

Örnek tam kod:

```text id="j4ogpq"
+k10>+k20<[->+<]>
```

Açıklama:

```text id="r3r5l3"
+k10      tape[0] = 10
>         tape[1]'e git
+k20      tape[1] = 20
<         tape[0]'a dön
[->+<]    tape[0]'daki 10'u tape[1]'e ekle, tape[0]'ı sıfırla
>         tape[1]'e git
```

Sonuç:

```text id="pfs6kf"
tape[0] = 0
tape[1] = 30
pointer = 1
```

Sonucu karakter olarak basarsan ASCII 30 görünür bir karakter olmayabilir. Bu yüzden küçük sayısal sonuçları ekrana karakter olarak basmak çoğu zaman iyi değildir. Bu dilde sayı yazdırma ayrı bir runtime desteği gerektirir. V3’ün temel halinde sayıları genellikle bar grafik, ASCII karakter veya açıklayıcı string ile göstermek daha uygundur.

---

## 24. Değeri kaybetmeden kopyalama

Bir değeri başka hücreye aktarırken kaynak değeri kaybetmek istemiyorsan daha karmaşık bir düzen gerekir. Örneğin `tape[0]` değerini hem `tape[1]` hem de `tape[2]` hücrelerine dağıtarak sonra geri kurabilirsin.

Başlangıç:

```text id="tcryaz"
tape[0] = A
tape[1] = 0
tape[2] = 0
pointer = 0
```

Kopyalama mantığı:

```text id="gm6son"
[->+>+<<]
```

Bu, aktif hücredeki değeri sağdaki iki hücreye taşır ve aktif hücreyi sıfırlar.

Sonra bir kopyayı geri almak için:

```text id="w99en5"
>>[-<<+>>]
```

Tam şablon:

```text id="y3l01e"
[->+>+<<]>>[-<<+>>]<<
```

Bu yapı şunu yapar:

```text id="s2i65z"
tape[0] değeri tape[1]'e kopyalanır
tape[0] eski değerine geri getirilir
tape[2] geçici hücre olarak kullanılır
```

Bu tür kodlar yeni başlayan için zor görünür. Fakat mantık basittir: Bir değeri korumak için önce iki kopya oluşturursun. Sonra kopyalardan birini kaynağı geri kurmak için kullanırsın.

BASIC’te:

```basic id="bfx579"
B = A
```

UX-MINIMA’da bu kadar kolay değildir. Çünkü burada değişken isimleri ve doğrudan atama yoktur. Bu yüzden bellek planı ve geçici hücreler çok önemlidir.

---

## 25. Çıkarma nasıl yapılır?

Aktif hücreden 1 çıkarmak için:

```text id="qv3vxc"
-
```

N kadar çıkarmak için:

```text id="yvqcdy"
-k10
```

Fakat iki hücre arasında çıkarma yapmak istiyorsan döngü kullanılır. Örneğin `tape[0]` değerini `tape[1]` değerinden çıkarmak istiyorsan:

Başlangıç:

```text id="yy1qc8"
tape[0] = 5
tape[1] = 20
pointer = 0
```

Kod:

```text id="a4yhk3"
[->-<]
```

Sonuç:

```text id="czvld0"
tape[0] = 0
tape[1] = 15
pointer = 0
```

Burada yine kaynak değer kaybolur. Bu pattern, “A’yı B’den çıkar ve A’yı sıfırla” anlamına gelir.

---

## 26. Sayaç nasıl kurulur?

Sayaç UX-MINIMA’nın en temel araçlarından biridir. Bir hücreye bir değer koyarsın, sonra döngü içinde her turda 1 azaltırsın.

Örnek:

```text id="cdoenc"
+k5[-]
```

Bu kod 5’ten 0’a kadar azaltır, ama dışarıya görünür bir şey yapmaz. Daha anlamlı örnek:

```text id="ly8xwz"
+k5>+k42<[>.<-]
```

Bu kod 5 tane `*` basar.

Sayaç tasarımında üç kural vardır:

```text id="t0dxt1"
1. Sayaç hücresini belirle.
2. Döngü sonunda pointer sayaç hücresine dönsün.
3. Her turda sayaç azalsın.
```

Eğer sayaç azalmazsa döngü sonsuz olur. Eğer pointer sayaç hücresine dönmezse `]` yanlış hücreyi kontrol eder. Eğer sayaç hücresini yanlışlıkla başka amaçla kullanırsan döngü bozulur.

---

## 27. FOR döngüsü nasıl kurulur?

BASIC’te şöyle yazarsın:

```basic id="e7x7nn"
FOR I = 1 TO 10
    PRINT "*";
NEXT I
```

UX-MINIMA’da FOR yoktur. Ama sayaç hücresiyle aynı mantığı kurarsın:

```text id="cshlei"
+k10>+k42<[>.<-]
```

Burada:

```text id="nr4ubv"
tape[0] = 10  yani döngü sayacı
tape[1] = 42  yani yıldız karakteri
```

Döngü gövdesi:

```text id="qduw3r"
>.<-
```

Bu gövde önce karakter hücresine gider, karakteri basar, sayaç hücresine döner ve sayacı azaltır.

Bu yüzden UX-MINIMA’da FOR döngüsü aslında şu şablondur:

```text id="o42hhf"
+kN
[
    gövde
    -
]
```

Ama gövde içinde başka hücrelere gidiyorsan, `-` komutundan önce mutlaka sayaç hücresine geri dönmelisin.

---

## 28. WHILE döngüsü nasıl kurulur?

BASIC veya Python’da WHILE döngüsü, koşul doğru olduğu sürece devam eder.

Python:

```python id="vap0fw"
while x != 0:
    x -= 1
```

UX-MINIMA’da `[` zaten aktif hücre sıfır değilken döngüye girer. Yani WHILE’ın en çıplak hali şudur:

```text id="dg8s8o"
[
    ...
]
```

Aktif hücre sıfır değilse çalışır. Bu yüzden UX-MINIMA’daki doğal döngü aslında WHILE döngüsüdür.

Örnek:

```text id="c2ngk1"
+k10[-]
```

Bu:

```python id="b6d2w1"
x = 10
while x != 0:
    x -= 1
```

mantığına benzer.

Döngü içinde koşul hücresini değiştirmek programcının sorumluluğudur. UX-MINIMA sana “bu döngü bitecek mi?” diye sormaz. Eğer aktif hücre hiç sıfıra gitmezse program sonsuza kadar döner.

---

## 29. IF yapısı nasıl kurulur?

UX-MINIMA’da IF yoktur ama karşılaştırma sonucu üreten komutlar vardır. Bu komutlar stack ile çalışır.

Şablon:

```text id="n9c7g6"
sol_değer $ sağ_değer ?
```

Bu eşitlik kontrolüdür.

Örnek:

```text id="ix2zlm"
+k65$0+k65?
```

Sonuç aktif hücreye yazılır:

```text id="mn0mjc"
1 = eşit
0 = eşit değil
```

Bu sonucu IF gibi kullanmak için:

```text id="evhrby"
+k65$0+k65?[
    yapılacak işler
    0
]
```

Blok sonunda `0` koymamızın sebebi şudur: `[` `]` aslında döngüdür. Eğer aktif hücre 1 olarak kalırsa, blok tekrar tekrar çalışır. Bu yüzden IF gibi kullanmak istiyorsak, blok sonunda flag’i sıfırlamalıyız.

Örnek:

```text id="injirw"
s1=0,{Dogru}
+k65$0+k65?[
p1
0
]
```

Bu şuna benzer:

```basic id="ybwxzs"
IF 65 = 65 THEN PRINT "Dogru"
```

Büyüktür kontrolü:

```text id="i5jf1y"
s1=0,{70 buyuktur 65}
+k70$0+k65![
p1
0
]
```

Küçüktür kontrolü:

```text id="lyesxu"
s1=0,{40 kucuktur 65}
+k40$0+k65;[
p1
0
]
```

---

## 30. IF-ELSE benzeri yapı nasıl kurulur?

IF-ELSE doğrudan yoktur. Fakat iki ayrı koşul bloğu kurarak benzetilebilir.

Örneğin 65 eşit mi 66?

```text id="lesu3f"
s1=0,{Esit}
s2=100,{Esit degil}
+k65$0+k66?[
p1
0
]
```

Bu eşitse `s1` yazar. Ama eşit değilse `s2` yazdırmak için ters koşul gerekir. UX-MINIMA’da doğrudan boolean NOT ile flag terslenebilir. Fakat `~` bitwise NOT olduğu için 0 değerini 255 yapar, 1 değerini 254 yapar. Bu doğrudan boolean NOT değildir.

Boolean NOT kurmak için güvenli yol şudur: Flag 0 veya 1 ise, 1’den flag değerini çıkarırsın. Fakat bu düşük seviyede biraz zahmetlidir. Bu yüzden V3’ün temel kullanımında IF-ELSE yerine iki ayrı açık koşul yazmak daha anlaşılırdır.

Örneğin:

```text id="u9rat5"
s1=0,{Esit}
s2=100,{Esit degil}
+k65$0+k66?[
p1
0
]
+k65$0+k66![
p2
0
]
+k65$0+k66;[
p2
0
]
```

Burada `65 > 66` yanlış, `65 < 66` doğru olduğu için `Esit degil` yazılır. Bu yöntem eşit değil durumunu iki olasılıkla kurar: büyüktür veya küçüktür.

Daha iyi bir tasarım için ileride boolean NOT patterni eklenebilir. Ama çekirdek V3 düşüncesinde, var olan komutlarla bu şekilde kurmak mümkündür.

---

## 31. INPUT nasıl kurulur?

BASIC’te:

```basic id="gpc4wc"
INPUT A$
PRINT A$
```

UX-MINIMA’da `,` komutu tek karakter okur. Okunan karakter aktif hücreye yazılır. Sonra `.` ile basılabilir.

```text id="blzkz0"
s1=0,{Bir tusa bas: }
s2=100,{Bastigin tus: }
p1
,
0+++++@
p2
.
```

Burada `,` tek karakter alır. `.` aktif hücreyi karakter olarak basar.

Çıktı örneği:

```text id="a1xgjr"
Bir tusa bas: 
Bastigin tus: A
```

Eğer kullanıcı `A` tuşuna bastıysa, aktif hücreye 65 yazılır ve sonra `.` ile `A` basılır.

Çok karakterli input almak istiyorsan her karakter için ayrı hücreye geçip `,` kullanman gerekir:

```text id="tzf92w"
,,,
```

Bu üç karakteri aynı hücreye üst üste yazar; sadece sonuncusu kalır. Üç karakteri üç hücreye almak için:

```text id="f5v1tr"
,>,>,
```

Bu kod:

```text id="x4thii"
tape[0] = birinci karakter
tape[1] = ikinci karakter
tape[2] = üçüncü karakter
pointer = tape[2]
```

anlamına gelir.

Bu örnek, string input’un aslında belleğe karakter karakter yazmak olduğunu gösterir.

---

## 32. PRINT nasıl kurulur?

UX-MINIMA’da iki tür yazdırma vardır.

Birincisi aktif hücreyi karakter olarak basan `.` komutudur:

```text id="ovykry"
+k65.
```

Bu `A` basar.

İkincisi data alanındaki stringi basan `pN` komutudur:

```text id="d3xqk1"
s1=0,{Merhaba}
p1
```

Bu `Merhaba` basar.

Sayı yazdırma çekirdek V3’ün doğal bir özelliği değildir. Eğer aktif hücrede 65 varsa `.` komutu `65` sayısını değil, ASCII 65 olan `A` karakterini basar. Bu fark çok önemlidir.

BASIC’te:

```basic id="iry8p5"
PRINT 65
```

ekrana `65` yazar. UX-MINIMA’da:

```text id="zwrb7z"
+k65.
```

ekrana `A` yazar.

Bu yüzden sayısal değerleri göstermek için üç yol vardır:

```text id="advsqg"
1. Değeri ASCII karakter olarak göstermek
2. Bar grafik gibi görselleştirmek
3. Runtime’a sayı yazdırma meta servisi eklemek
```

Çekirdek kullanımda en pratik yöntem bar grafiktir.

---

## 33. Bar grafik ile sayı gösterme

Diyelim ki elimizde 12 birimlik bir değer var. Bunu sayı olarak `12` yazmak yerine 12 tane `#` ile gösterebiliriz.

```text id="v6l5ap"
s1=0,{Olcum: }
p1
+k12>+k35<[>.<-]
```

Açıklama:

```text id="rz3cwc"
+k12    sayaç = 12
>       karakter hücresine git
+k35    ASCII 35, yani #
<       sayaç hücresine dön
[       sayaç sıfır değilken
>       karakter hücresine git
.       # bas
<       sayaç hücresine dön
-       sayaç azalt
]       devam et
```

Çıktı:

```text id="a2w0zx"
Olcum: ############
```

Bu yöntem bilimsel modellemelerde çok kullanışlıdır. Örneğin OD değeri, pH seviyesi, ışık şiddeti, popülasyon yoğunluğu veya reaksiyon ürünü miktarı bar grafikle temsil edilebilir.

---

## 34. Dizi nasıl düşünülür?

UX-MINIMA’da tape zaten dizidir. Python’da şöyle yazarsın:

```python id="smkww2"
a = [10, 20, 30, 40]
```

UX-MINIMA’da bunu şöyle düşünürsün:

```text id="p3xmjo"
tape[0] = 10
tape[1] = 20
tape[2] = 30
tape[3] = 40
```

Kod:

```text id="zdxrr3"
+k10>+k20>+k30>+k40
```

Bu bir dizi gibi düşünülebilir. Ancak dizi elemanına isimle veya indeksle erişim yoktur. Pointer’ı doğru hücreye götürmen gerekir.

Eğer dizinin başına dönmek istiyorsan:

```text id="y5jvkl"
<k3
```

Çünkü dört eleman yazdıktan sonra pointer `tape[3]` üzerindedir. `tape[0]` hücresine dönmek için üç kez sola gitmek gerekir.

Bu yüzden uzun dizilerde pointer konumunu takip etmek zorlaşır. UX-MINIMA’da diziyle çalışmak için düzenli bellek planı gerekir.

---

## 35. Data alanı nasıl düşünülür?

Tape aktif işlem alanıdır. Stack geçici saklama alanıdır. Data alanı ise daha çok sabit veri, string, tablo veya model verisi için kullanılır.

String tanımları data alanına yazılır:

```text id="kf74hu"
s1=0,{Baslik}
s2=100,{Hata mesaji}
s3=200,{Sonuc}
```

Burada data alanı şu şekilde kullanılır:

```text id="k9wk1g"
data[0...]   = Baslik stringi
data[100...] = Hata mesaji stringi
data[200...] = Sonuc stringi
```

Bu tasarımda programcı data alanının çakışmamasına dikkat etmelidir. Eğer `s1` çok uzun olursa ve `s2` başlangıç hücresi çok yakınsa, iki string çakışabilir. Compiler basit sınır kontrolü yapabilir ama stringlerin birbirini örtmesini kontrol etmek ayrıca tasarlanmalıdır.

İyi kullanım:

```text id="oi8zlm"
s1=0,{Kisa mesaj}
s2=100,{Baska mesaj}
s3=200,{Ucuncu mesaj}
```

Kötü kullanım:

```text id="ldn8bs"
s1=0,{Bu cok uzun bir metin olabilir}
s2=5,{Bu oncekiyle cakisir}
```

Data alanını kullanırken de bellek haritası yapmak gerekir.

---

## 36. Stack’te veri saklama

Stack, kısa süreli saklama içindir. Bir değeri sonra kullanmak üzere stack’e atabilirsin:

```text id="jjix1m"
+k65$
```

Sonra başka hücreye geçip geri alabilirsin:

```text id="qd3qny"
>%
```

Tam örnek:

```text id="yhn1ey"
+k65$>%.
```

Bu `A` basar.

Stack’in iyi kullanım alanları:

```text id="cou931"
1. Karşılaştırma için sol değeri saklama
2. Bitwise işlem için birinci operandı saklama
3. Geçici değer taşıma
4. LIFO mantığını göstermek
```

Stack’in kötü kullanım alanları:

```text id="ah7z2o"
1. Uzun süreli veri saklama
2. Çok karmaşık veri yapısı kurma
3. Hangi sırada ne attığını takip etmeden kullanma
```

Stack görünmez olduğu için, yeni başlayan programcı için hata kaynağıdır. Her `$` bir gün `%` ile dengelenmelidir. Karşılaştırma ve bitwise komutlar da stack’ten değer tüketir. Bu yüzden stack derinliğini zihinde takip etmek gerekir.

---

## 37. Stringleri stack’te saklama meselesi

UX-MINIMA V3’te stringler doğal olarak data alanında saklanır. Stack ise hücre değerleri saklar. Bir stringi doğrudan tek seferde stack’e atmak yoktur. Ama stringin karakterlerini tek tek stack’e atmak mümkündür.

Örneğin `A`, `B`, `C` karakterlerini stack’e atalım:

```text id="y4qag6"
+k65$0+k66$0+k67$
```

Stack sırası:

```text id="bnsw8v"
top = 67 yani C
      66 yani B
      65 yani A
```

Şimdi pop edip basarsak:

```text id="jd29vj"
%.%.%.
```

Çıktı:

```text id="gu5l59"
CBA
```

Çünkü stack LIFO’dur. Son giren ilk çıkar.

Eğer `ABC` basmak istiyorsan stack’e ters sırada atmalısın:

```text id="d7aulj"
+k67$0+k66$0+k65$%.%.%.
```

Çıktı:

```text id="ubfc5n"
ABC
```

Bu örnek stack’in string saklamak için doğal bir yer olmadığını gösterir. Stringler data alanında daha düzenli durur. Stack, kısa süreli karakter veya değer tersleme işlemleri için uygundur.

---

## 38. Fonksiyon yoksa tekrar eden kod nasıl yönetilir?

UX-MINIMA V3 çekirdeğinde fonksiyon yoktur. Fakat tekrar eden işleri üç şekilde yönetebilirsin.

Birinci yol, pattern optimizer’dır. Örneğin `[->+<]` sık kullanılan bir pattern olduğu için compiler bunu optimize ASM’ye çevirebilir. Bu kullanıcı açısından fonksiyon gibi değildir ama compiler açısından tekrar eden yapıyı tanıma yöntemidir.

İkinci yol, string ve meta kullanımıdır. Sık kullanılan mesajları data alanına koyup `pN` ile basabilirsin:

```text id="tov6ll"
s1=0,{Hata}
s2=100,{Tamam}
p1
p2
```

Üçüncü yol, kaynak dosyada yorum ve blok düzeni kullanmaktır. Örneğin bir yıldız çizgisi basan kodu tekrar kullanacaksan, yorumla işaretlersin:

```text id="okduxq"
# 10 yildiz bas
+k10>+k42<[>.<-]
```

Gerçek anlamda fonksiyon veya alt program sistemi yoktur. Bu dilde fonksiyon yerine bellek şablonu, pattern ve disiplinli tekrar kullanımı vardır.

---

## 39. Gerçek dünya problemi: basit ölçüm ekranı

Bir sensör sisteminden üç değer geldiğini düşünelim. UX-MINIMA’da gerçek sensör okuma yoksa bile bu değerleri simüle edebiliriz.

Bellek planı:

```text id="k6ivlv"
tape[0] = OD değeri bar uzunluğu
tape[1] = karakter
tape[2] = pH değeri bar uzunluğu
tape[3] = sıcaklık bar uzunluğu
```

Program:

```text id="wb13yt"
s1=0,{OD680 : }
s2=100,{pH    : }
s3=200,{Temp  : }
p1
+k12>+k35<[>.<-]
0+++++@
p2
+k8>+k42<[>.<-]
0+++++@
p3
+k15>+k43<[>.<-]
```

Çıktı:

```text id="ye191d"
OD680 : ############
pH    : ********
Temp  : +++++++++++++++
```

Bu program, UX-MINIMA’nın bilimsel gösterimlerde nasıl kullanılabileceğini gösterir. Sayı yazdırma yoktur ama görsel temsil vardır. Bu, özellikle eğitim amaçlı modellemelerde yeterli olabilir.

---

## 40. Gerçek dünya problemi: basit karar sistemi

Diyelim ki bir değer eşik üstündeyse uyarı yazmak istiyoruz.

BASIC:

```basic id="bior70"
IF A > 10 THEN PRINT "Uyari"
```

UX-MINIMA:

```text id="blf5md"
s1=0,{Uyari: esik asildi}
+k12$0+k10![
p1
0
]
```

Burada 12 değeri stack’e atılır, 10 ile karşılaştırılır, `!` komutu “stackTop > current” kontrolü yapar. Sonuç 1 ise blok çalışır.

Bu örnek, IF yapısının UX-MINIMA’da nasıl kurulduğunu gösterir. Programcı burada `A` adlı bir değişken görmez. `A` değeri aktif hücrede kurulmuştur. Bu yüzden UX-MINIMA’da koşul yazmadan önce değerlerin hangi hücrede ve hangi sırada olduğunu bilmek gerekir.

---

## 41. Bölüm 2 özeti

Bu bölümde BASIC ve Python gibi dillerde hazır gelen yapıların UX-MINIMA’da nasıl kurulabileceğini gördük. Değişkenlerin tape hücreleriyle, sabitlerin programcı disipliniyle, atamanın `0+kN` ile, toplamanın ve çıkarmanın döngü patternleriyle, FOR ve WHILE döngülerinin sayaç hücreleriyle, IF yapısının karşılaştırma ve `[ ]` bloğuyla, input’un `,` komutuyla, output’un `.` ve `pN` komutlarıyla, dizilerin tape üzerinde ardışık hücrelerle, stringlerin data alanıyla, geçici değerlerin stack ile kurulabileceğini anlattık.

Bu dilde diğer dillerdeki yapıları birebir aramak yerine, onların en küçük davranışlarını kurmayı öğrenmek gerekir. Değişken aslında hücredir. Liste aslında ardışık hücrelerdir. IF aslında bir flag hücresinin sıfır olup olmamasıdır. FOR aslında azalan bir sayaçtır. PRINT bazen karakter basmak, bazen data alanından string okumaktır. Fonksiyon ise bu çekirdekte yoktur; onun yerine pattern, tekrar ve disiplinli bellek planı vardır.

Bundan sonraki bölümde daha fazla örnek program yazacağız. Tahmin oyunu mantığına hazırlık, karakter girişleri, basit oyun ekranları, DNA/RNA/protein dizilerinin tape üzerinde temsil edilmesi, kimyasal çorba ve yaşayan hücre modeline giriş gibi konulara geçeceğiz. Ayrıca data alanı, stack ve tape’in bilimsel modelleme açısından nasıl birlikte düşünülebileceğini örneklerle anlatacağız.

**Bölüm 2/4 burada bitti.**

```
```


````markdown id="pjvdy3"
## Bölüm 3/4 — Örnek Programlar, Oyun Mantığı, DNA/RNA/Protein Modelleme ve Bilimsel Düşünme

---

## 42. Bu bölümde ne yapacağız?

İlk iki bölümde UX-MINIMA x64 V3 dilinin komutlarını, tape sistemini, stack mantığını, data alanını, string kullanımını, döngüleri, koşulları ve BASIC/Python’daki yapıların bu dilde nasıl kurulabileceğini gördük. Bu bölümde artık daha somut programlar yazacağız. Amacımız devasa uygulamalar yazmak değildir. Amacımız, bu dilin küçük ama güçlü yapı taşlarıyla oyun, karar sistemi, biyolojik dizi modeli, kimyasal reaksiyon benzetimi ve basit bilimsel görselleştirme gibi fikirlerin nasıl kurulabileceğini görmektir.

UX-MINIMA’da program yazarken her zaman şunu hatırlamalısın: Bu dil sana hazır “yüksek seviye” konfor sunmaz. Ama sana çok temel parçalar verir. Bu parçalarla kendi düşünce sistemini kurarsın. Eğer BASIC veya Python’da bir problemi “değişkenler ve komutlar” olarak düşünüyorsan, UX-MINIMA’da aynı problemi “hücreler, pointer, stack, flag, döngü ve data alanı” olarak düşünmelisin.

---

## 43. Örnek program: başlık ekranı

En basit programlardan biri, ekrana bir başlık ve açıklama yazdırmaktır. Bunun için data alanındaki string sistemi kullanılır.

```text id="n1l7ld"
# basit baslik ekrani
s1=0,{UX-MINIMA x64 V3}
s2=100,{Tape, stack ve data alanli mini compiler}
s3=200,{Program basladi}
p1
0+++++@
p2
0+++++@
p3
````

Bu programda `s1`, `s2`, `s3` data alanına stringleri yerleştirir. `p1`, `p2`, `p3` bu stringleri basar. `0+++++@` meta servis 5’i çağırır ve yeni satır üretir.

Çıktı yaklaşık olarak şöyle olur:

```text id="x9ktrb"
UX-MINIMA x64 V3
Tape, stack ve data alanli mini compiler
Program basladi
```

Bu program basit görünür ama önemli bir şeyi gösterir: UX-MINIMA’da uzun metinleri `+` ve `.` komutlarıyla tek tek üretmek zorunda değilsin. Stringler data alanında tutulur ve `pN` ile basılır.

---

## 44. Örnek program: karakter üretme

Aktif hücreye ASCII değeri koyup `.` ile karakter basabilirsin.

```text id="f3rtmr"
# A harfi bas
+k65.
```

Çıktı:

```text id="hku5mw"
A
```

Ardışık karakterler basmak için pointer ve hücreleri kullanabilirsin.

```text id="hk1cum"
# ABC bas
+k65.0+k66.0+k67.
```

Bu program aynı hücreyi tekrar tekrar sıfırlar, yeni değer verir ve karakter basar.

Çıktı:

```text id="w8qxar"
ABC
```

Aynı işi farklı hücrelerde de yapabilirsin:

```text id="vxsmn2"
# ABC farkli hucrelerde
+k65>+k66>+k67<k2.>.>.
```

Bu kodda önce üç hücreye `A`, `B`, `C` değerleri yerleştirilir. Sonra pointer başa döndürülür ve sırayla karakterler basılır.

---

## 45. Örnek program: tekrar eden çizgi

Bir programda ekrana çizgi basmak isteyebilirsin. Bunun için sayaç döngüsü kullanılır.

```text id="sj7uh3"
# 30 tane tire bas
+k30>+k45<[>.<-]
```

ASCII 45 `-` karakteridir. Çıktı:

```text id="bvu2f0"
------------------------------
```

Bu programın bellek planı:

```text id="lowot5"
tape[0] = sayaç
tape[1] = basılacak karakter
```

Döngü mantığı:

```text id="zslx0n"
sayaç sıfır değilken:
    karakter hücresine git
    karakter bas
    sayaç hücresine dön
    sayaç azalt
```

Bu yapı çok önemlidir. İleride bar grafik, yükleme animasyonu, ölçüm çubuğu, hücre popülasyonu gösterimi gibi işlerde aynı mantık kullanılacaktır.

---

## 46. Örnek program: ölçüm barı

Bir bilimsel ölçümü sayı olarak değil, görsel bar olarak göstermek UX-MINIMA’da çok doğaldır.

```text id="wmu82h"
# OD680 olcum bari
s1=0,{OD680: }
p1
+k18>+k35<[>.<-]
```

ASCII 35 `#` karakteridir. Çıktı:

```text id="p8dj7d"
OD680: ##################
```

Bu tarz gösterimle farklı bilimsel değerler temsil edilebilir:

```text id="mwld7t"
# uc farkli olcum
s1=0,{OD680 : }
s2=100,{pH    : }
s3=200,{Sicak : }
p1
+k18>+k35<[>.<-]
0+++++@
p2
+k7>+k42<[>.<-]
0+++++@
p3
+k24>+k43<[>.<-]
```

Çıktı:

```text id="kl6h9y"
OD680 : ##################
pH    : *******
Sicak : ++++++++++++++++++++++++
```

Bu örnek, UX-MINIMA’nın bilimsel verileri görselleştirmede nasıl kullanılabileceğini gösterir. Dil decimal sayı yazdırma konusunda zayıf olabilir, ama bar temelli temsil için uygundur.

---

## 47. Tahmin oyunu mantığına giriş

UX-MINIMA’da tam anlamıyla gelişmiş bir oyun yazmak zordur, çünkü yüksek seviyeli input, sayı yazdırma, random aralık kontrolü ve IF-ELSE yapıları doğrudan hazır değildir. Fakat küçük bir karakter tahmin oyunu kurulabilir.

Oyunun fikri şu olsun: Program kullanıcıdan bir karakter ister. Eğer kullanıcı `A` girerse “dogru” yazsın. Eğer farklı bir karakter girerse bu temel sürümde hiçbir şey yazmasın.

ASCII’de `A = 65`.

Program:

```text id="wiflor"
# karakter tahmin oyunu
s1=0,{Tahmin oyunu}
s2=100,{A harfine bas: }
s3=200,{Dogru tahmin}
p1
0+++++@
p2
,
$0+k65?[
0+++++@
p3
0
]
```

Bu programda `,` kullanıcının bastığı karakteri aktif hücreye alır. `$` bu değeri stack’e atar. Sonra aktif hücre sıfırlanır ve 65 yapılır. `?` stack’teki kullanıcı girişi ile 65’i karşılaştırır. Eğer eşitse aktif hücre 1 olur ve `[ ... ]` bloğu çalışır.

Blok içinde yeni satır basılır, `p3` ile “Dogru tahmin” yazılır ve `0` ile flag sıfırlanır.

Bu programın BASIC karşılığı yaklaşık şöyledir:

```basic id="f7a2va"
PRINT "Tahmin oyunu"
PRINT "A harfine bas: "
INPUT K$
IF K$ = "A" THEN
    PRINT "Dogru tahmin"
END IF
```

UX-MINIMA’da bu kod daha zahmetlidir ama daha öğreticidir. Çünkü karakterin ASCII değerini, stack’i, karşılaştırmayı ve flag ile koşullu bloğu açıkça görürsün.

---

## 48. Tahmin oyununda yanlış cevap durumu

Bir önceki program sadece doğru cevapta mesaj yazıyordu. Yanlış cevapta mesaj yazmak için eşit değil durumunu kurmamız gerekir. Çekirdek UX-MINIMA’da doğrudan “eşit değil” komutu yoktur. Ama eşit değil durumu “küçüktür veya büyüktür” olarak kurulabilir.

Eğer kullanıcı girişi 65’ten küçükse yanlış, 65’ten büyükse yanlış. Eşitse doğru.

Basit yaklaşım:

```text id="jcncvw"
# A tahmin oyunu, dogru ve yanlis mesajli
s1=0,{A harfine bas: }
s2=100,{Dogru}
s3=200,{Yanlis}
p1
,
$0+k65?[
0+++++@
p2
0
]
$0+k65![
0+++++@
p3
0
]
$0+k65;[
0+++++@
p3
0
]
```

Bu kodda dikkat edilmesi gereken bir sorun vardır. İlk `?` karşılaştırması stack’ten kullanıcı girişini tüketir. Sonraki `!` ve `;` karşılaştırmaları için aynı kullanıcı girişini tekrar stack’e koymak gerekir. Fakat yukarıdaki kodda bu yapılmamıştır. Bu örnek, UX-MINIMA’da stack tüketiminin ne kadar önemli olduğunu göstermek için özellikle öğreticidir.

Doğru tasarımda kullanıcı girişini bir hücrede saklamak, sonra her karşılaştırmadan önce o hücreden stack’e almak gerekir. Çekirdek dilde hücre değerini kaybetmeden stack’e almak mümkündür; aktif hücrede giriş duruyorsa `$` ile stack’e atılır. Ama karşılaştırma sonrası aktif hücre flag olur. Bu yüzden giriş değerini korumak için önce başka hücreye kopyalama gerekir.

Bu nokta önemlidir: UX-MINIMA’da basit görünen IF-ELSE bile bellek tasarımı ister. Diğer dillerde runtime ve compiler senin yerine değerleri saklar. UX-MINIMA’da sen saklarsın.

---

## 49. Tahmin oyunu için daha sağlam bellek planı

Sağlam tahmin oyunu için önce bellek planı yapalım.

```text id="coxmc8"
tape[0] = kullanıcı girişi
tape[1] = geçici kopya
tape[2] = sabit 65
tape[3] = flag
```

Bu planla önce kullanıcı girişini `tape[0]` hücresine alırız. Sonra karşılaştırma yapmak için bu değeri stack’e koyarız ve karşılaştırma değerini aktif hücrede oluştururuz. Fakat pointer hareketleri dikkat ister.

Çekirdek UX-MINIMA ile bu program uzunlaşır. Bu yüzden pratik ders şudur: Oyun yazarken önce değerlerin nerede kalacağını tasarlamalısın. Özellikle input değerini birden fazla kez kullanacaksan, onu kaybetmeyecek şekilde kopyalamalısın.

Tam oyun yazmak mümkündür, ama programcıdan çok dikkat ister. Bu yüzden başlangıçta “doğru tahmin olursa mesaj yaz” düzeyi yeterli bir alıştırmadır.

---

## 50. Karakter tabanlı oyun ekranı

Oyun sadece karar vermek değildir. Ekranda oyun dünyası göstermek de önemlidir. UX-MINIMA string sistemiyle basit oyun ekranları kurabilir.

```text id="oalhsd"
# basit oda ekrani
s1=0,{+----------------+}
s2=100,{|      @         |}
s3=200,{|                |}
s4=300,{|          *     |}
s5=400,{+----------------+}
p1
0+++++@
p2
0+++++@
p3
0+++++@
p4
0+++++@
p5
```

Çıktı:

```text id="h2ijm2"
+----------------+
|      @         |
|                |
|          *     |
+----------------+
```

Burada `@` oyuncu, `*` hedef gibi düşünülebilir. Bu ekran gerçek zamanlı hareket ettirmez ama oyun dünyası fikrini gösterir. Daha gelişmiş hareket için input alınıp farklı string ekranları basılabilir. Örneğin `w`, `a`, `s`, `d` tuşlarına göre farklı ekranlar seçmek mümkündür ama her seçim için karşılaştırma ve koşul blokları gerekir.

---

## 51. DNA modelleme: tape bir dizi olabilir

DNA dizisi harflerden oluşur:

```text id="e51ci8"
A C G T
```

UX-MINIMA’da her harfi bir sayıyla temsil edebiliriz:

```text id="xgto04"
A = 1
C = 2
G = 3
T = 4
```

O zaman DNA dizisi tape üzerinde şöyle tutulabilir:

```text id="s6wqld"
tape[0] = 1
tape[1] = 4
tape[2] = 3
tape[3] = 2
```

Bu şu diziyi temsil eder:

```text id="ervh4c"
A T G C
```

Kod:

```text id="u4bd1l"
# DNA: A T G C
+k1>+k4>+k3>+k2
```

Burada tape artık sadece program değişkenleri değil, biyolojik bir dizidir. Pointer ise bu dizinin üzerinde gezen okuma kafası gibi düşünülebilir.

---

## 52. DNA bazı tanıma

Diyelim ki aktif hücredeki baz A mı diye kontrol etmek istiyoruz. A kodu 1 olsun.

```text id="vatfmi"
s1=0,{Baz A bulundu}
+k1$0+k1?[
p1
0
]
```

Bu örnek doğrudan `1 == 1` kontrolü yapar. Daha gerçekçi kullanımda aktif hücrede DNA baz kodu durur. Program onu stack’e atar, sonra 1 ile karşılaştırır. Eşitse mesaj basar.

BASIC mantığı:

```basic id="qt4nis"
IF base = 1 THEN PRINT "Baz A bulundu"
```

UX-MINIMA mantığı:

```text id="ev2e0z"
base değerini aktif hücrede tut
$ ile stack'e koy
aktif hücreyi 1 yap
? ile karşılaştır
sonuç 1 ise bloğa gir
```

Bu yöntem C, G, T için de kullanılabilir.

---

## 53. DNA tamamlayıcı zincir fikri

DNA’da eşleşmeler şöyledir:

```text id="mfnics"
A ↔ T
C ↔ G
```

Sayısal kodla:

```text id="je01bp"
1 ↔ 4
2 ↔ 3
```

Bir bazın tamamlayıcısını üretmek için şöyle düşünürsün:

```text id="f4h2q7"
eğer baz 1 ise çıktı 4
eğer baz 4 ise çıktı 1
eğer baz 2 ise çıktı 3
eğer baz 3 ise çıktı 2
```

UX-MINIMA’da bu işlem birden fazla IF bloğu gerektirir. Her karşılaştırma için baz değerini korumak gerekir. Bu da kopyalama veya stack kullanımını önemli hale getirir.

Basit düşünsel şablon:

```text id="ercabv"
# aktif hücrede baz var
# baz == 1 ise yan hücreye 4 yaz
# baz == 4 ise yan hücreye 1 yaz
# baz == 2 ise yan hücreye 3 yaz
# baz == 3 ise yan hücreye 2 yaz
```

Bu programı tam yazmak uzun olur. Ama fikir önemlidir: DNA tamamlayıcı zinciri, tape üzerinde koşullu dönüşüm problemidir. UX-MINIMA bu tür dönüşümleri anlamak için çok öğretici bir araçtır.

---

## 54. RNA modelleme

RNA’da genellikle bazlar şöyle düşünülür:

```text id="htiqn0"
A U G C
```

Kodlama:

```text id="b3z9is"
A = 1
U = 2
G = 3
C = 4
```

Örneğin `AUG` başlangıç kodonu olarak düşünülebilir. Tape üzerinde:

```text id="rzz458"
tape[0] = 1
tape[1] = 2
tape[2] = 3
```

Kod:

```text id="g5z8ck"
# RNA kodonu AUG
+k1>+k2>+k3
```

Bir kodon tanımak için üç hücre arka arkaya kontrol edilir. Örneğin `AUG` için:

```text id="kc1u0u"
tape[i]   == 1
tape[i+1] == 2
tape[i+2] == 3
```

UX-MINIMA’da bu, üç karşılaştırma ve bunların sonucunu birleştirme problemi haline gelir. Çekirdek dilde AND bitwise komutu vardır ama boolean flagleri dikkatli kullanmak gerekir. Eğer her karşılaştırma sonucu 0 veya 1 ise, bu flagler AND ile birleştirilebilir.

Düşünce şablonu:

```text id="g4ub2o"
flag0 = cell0 == 1
flag1 = cell1 == 2
flag2 = cell2 == 3
sonuc = flag0 AND flag1 AND flag2
```

Bu, diğer dillerde tek satırda yazılır:

```python id="ml9scc"
if rna[i] == 1 and rna[i+1] == 2 and rna[i+2] == 3:
    print("AUG bulundu")
```

UX-MINIMA’da ise her flag için ayrı hücre ve stack planı gerekir.

---

## 55. Protein dizisi modelleme

Protein dizisi aminoasitlerden oluşur. Her aminoaside bir sayı verilebilir. Örneğin basit bir eğitim kodlaması:

```text id="zl2xf3"
Ala = 1
Cys = 2
Gly = 3
Lys = 4
Met = 5
Stop = 0
```

Tape üzerinde protein dizisi:

```text id="zf4xml"
tape[0] = 5
tape[1] = 1
tape[2] = 3
tape[3] = 2
tape[4] = 0
```

Bu şu anlama gelebilir:

```text id="du2qw0"
Met - Ala - Gly - Cys - Stop
```

Kod:

```text id="d9wiyo"
# protein: Met Ala Gly Cys Stop
+k5>+k1>+k3>+k2>0
```

Stop kodu 0 olduğu için UX-MINIMA döngüleriyle uyumlu bir fikir oluşur. Çünkü `[` komutu aktif hücre 0 olduğunda döngüye girmez. Eğer bir protein zinciri 0 ile bitiyorsa, pointer hücre hücre ilerleyerek stop koduna kadar tarama fikri kurulabilir.

Bu, tape modelinin biyolojik dizilere neden uygun olduğunu gösterir.

---

## 56. Protein motif arama

Diyelim ki Cys kodu 2 olsun. Protein dizisinde Cys var mı diye bakmak istiyoruz. Eğer aktif hücredeki aminoasit 2 ise mesaj yazdırabiliriz.

```text id="fxngtc"
s1=0,{Cys bulundu}
+k2$0+k2?[
p1
0
]
```

Bu örnek doğrudan 2 ile 2’yi karşılaştırır. Gerçek dizide pointer protein dizisi üzerinde gezer, her hücredeki değeri 2 ile karşılaştırır ve eşitse mesaj basar.

Motif arama daha karmaşıktır. Örneğin `Met-Ala-Gly` motifini aramak için üç hücre peş peşe kontrol edilir. Bu, RNA kodon tanıma problemine benzer.

UX-MINIMA burada bilimsel bir oyuncak model olarak değerlidir. Gerçek biyoinformatik için Python, R, C veya özel kütüphaneler kullanılır. Ama UX-MINIMA ile dizi, pointer, karşılaştırma ve motif mantığı çok çıplak şekilde anlaşılır.

---

## 57. Kimyasal çorba modeli

Tape hücrelerini kimyasal maddelerin miktarı gibi düşünebiliriz.

```text id="yqviao"
tape[0] = A maddesi
tape[1] = B maddesi
tape[2] = C ürünü
```

Basit reaksiyon:

```text id="o7yfel"
A → B
```

UX-MINIMA:

```text id="qgyqms"
+k10[->+<]
```

Başlangıç:

```text id="grebfc"
A = 10
B = 0
```

Sonuç:

```text id="uwiqte"
A = 0
B = 10
```

Bu, kimyasal dönüşüm gibi düşünülebilir. A maddesinden her tur 1 azalır, B maddesi 1 artar.

Daha farklı reaksiyon:

```text id="gf1lmy"
A → 2B
```

Kod:

```text id="m8rgz3"
+k10[->++<]
```

Sonuç:

```text id="tm3v6g"
A = 0
B = 20
```

Bu stokiyometrik düşünmeyi öğretmek için ilginç bir modeldir.

---

## 58. Eşik kontrollü reaksiyon

Diyelim ki A maddesi 10’dan büyükse reaksiyon başlasın. A miktarı 12 olsun.

```text id="xyb7lh"
s1=0,{Reaksiyon basladi}
+k12$0+k10![
p1
0
]
```

Burada `12 > 10` kontrol edilir. Sonuç doğruysa mesaj yazılır.

Daha gelişmiş bir modelde bu koşul sağlanınca A’dan B’ye dönüşüm başlatılabilir. Bunun için koşul flag’i ve reaksiyon döngüsü dikkatli birleştirilmelidir. UX-MINIMA’da böyle bir program yazmak mümkündür ama programcı pointer ve flag hücresini çok dikkatli yönetmelidir.

---

## 59. Yaşayan hücre modeline giriş

Yaşayan bir hücreyi çok basitleştirerek tape üzerinde modelleyebiliriz. Örneğin:

```text id="srhlyj"
tape[0] = enerji
tape[1] = besin
tape[2] = atık
tape[3] = büyüme seviyesi
tape[4] = stres seviyesi
```

Basit kurallar:

```text id="w9d9bm"
besin varsa enerji artsın
enerji varsa büyüme artsın
atık artarsa stres artsın
stres eşik üstü ise uyarı yazılsın
```

UX-MINIMA ile bu kuralların her biri hücre dönüşümü ve eşik kontrolü olarak kurulabilir. Örneğin besinden enerjiye dönüşüm:

```text id="sh5gxx"
# tape[0] = besin gibi düşün
# tape[1] = enerji gibi düşün
+k10[->+<]
```

Bu model gerçek biyoloji değildir. Ama modelleme düşüncesi için yararlıdır. Çünkü yaşayan sistemleri soyut değişkenler, akışlar, dönüşümler, eşikler ve feedback yapıları olarak düşünmeyi öğretir.

UX-MINIMA gibi bir dil, gerçek bilimsel hesaplama dili olmaktan çok, bilimsel sistemlerin en küçük hesaplama mantığını göstermek için kullanışlıdır.

---

## 60. Data, stack ve tape bilimsel modelde nasıl birlikte kullanılır?

Bilimsel bir model kurarken üç alanı farklı rollerle düşünmek gerekir.

Tape, aktif durum alanıdır. Anlık değişen değerler burada tutulur. Örneğin enerji, besin, atık, hücre sayısı, ışık seviyesi gibi değerler tape hücreleri olabilir.

Stack, geçici işlem alanıdır. Karşılaştırmalar, bitwise işlemler ve kısa süreli değer saklama için kullanılır. Örneğin “A değerini B ile karşılaştırmadan önce stack’e at” mantığı burada çalışır.

Data alanı, sabit açıklamalar ve model metinleri için uygundur. Örneğin “Enerji düştü”, “Stres arttı”, “Reaksiyon başladı” gibi mesajlar data alanında string olarak durabilir.

Örnek:

```text id="o1lxkx"
s1=0,{Enerji seviyesi dusuk}
s2=100,{Stres esigi asildi}
s3=200,{Besin enerjiye donustu}
```

Tape model verisini taşır. Data modelin açıklama metinlerini taşır. Stack ise hesap sırasında görünmez yardımcı alan olur.

Bu ayrım, daha büyük sistemler tasarlarken çok değerlidir.

---

## 61. UX-MINIMA ile düşünme egzersizi

Bir problemi UX-MINIMA’ya çevirmek için şu sırayı izleyebilirsin:

```text id="y4dcex"
1. Problemde hangi değerler var?
2. Her değeri hangi tape hücresine koyacağım?
3. Hangi değerler sabit kalacak?
4. Hangi değerler değişecek?
5. Hangi değerler geçici olarak stack’e atılacak?
6. Hangi mesajlar data alanında duracak?
7. Döngü hangi hücreye bağlı olacak?
8. Koşul sonucu hangi hücrede flag olacak?
9. Döngü sonunda pointer doğru hücreye dönüyor mu?
10. Programın sonunda hangi hücrelerin değeri önemli?
```

Bu sorulara cevap vermeden doğrudan kod yazmaya başlarsan, UX-MINIMA programı kısa sürede anlaşılmaz hale gelir.

Bu dil, programcıya disiplin öğretir. Diğer dillerde compiler, runtime ve değişken isimleri sana yardım eder. UX-MINIMA’da yardım azdır; bu yüzden düşünce daha açık ve planlı olmak zorundadır.

---

## 62. Gerçek dünya problemi: mini laboratuvar göstergesi

Diyelim ki bir laboratuvar sisteminde üç değer göstermek istiyorsun: besin, enerji, stres. Sayısal çıktı yerine bar grafik kullanacağız.

```text id="ufqymw"
# mini laboratuvar gostergesi
s1=0,{Besin : }
s2=100,{Enerji: }
s3=200,{Stres : }
p1
+k14>+k35<[>.<-]
0+++++@
p2
+k9>+k42<[>.<-]
0+++++@
p3
+k4>+k33<[>.<-]
```

ASCII 35 `#`, 42 `*`, 33 `!` karakteridir.

Çıktı:

```text id="d17c77"
Besin : ##############
Enerji: *********
Stres : !!!!
```

Bu örnek UX-MINIMA’nın gerçek bilimsel hesap yapmasından çok, bilimsel durumları sembolik ve görsel olarak temsil etmede kullanılabileceğini gösterir.

---

## 63. Gerçek dünya problemi: basit kalite kontrol

Bir ürün ölçüm değerinin eşik üstü olup olmadığını kontrol edelim. Ölçüm 18, eşik 15 olsun.

```text id="m7bz22"
# kalite kontrol
s1=0,{Kalite kontrol}
s2=100,{Uygun: esik ustu}
p1
0+++++@
+k18$0+k15![
p2
0
]
```

Burada `18 > 15` doğru olduğu için mesaj yazılır.

Eğer ölçüm düşük olsaydı:

```text id="xdk1l4"
+k12$0+k15![
p2
0
]
```

mesaj yazılmazdı.

Bu program karar sisteminin temelidir. Daha gelişmiş kalite kontrol için birden fazla eşik, birden fazla mesaj ve birden fazla flag hücresi gerekir.

---

## 64. Gerçek dünya problemi: karakter parolası

Kullanıcıdan tek karakterli bir parola isteyelim. Parola `X` olsun. ASCII’de `X = 88`.

```text id="kw2aa8"
# tek karakter parola
s1=0,{Parola karakterini gir: }
s2=100,{Giris basarili}
p1
,
$0+k88?[
0+++++@
p2
0
]
```

Bu programda kullanıcı `X` girerse mesaj yazılır. Başka karakter girerse sessiz kalır.

Bu örnek, UX-MINIMA ile basit güvenlik veya kontrol akışlarının nasıl kurulabileceğini gösterir. Gerçek güvenlik için elbette uygun değildir. Ama input, ASCII, karşılaştırma ve koşullu blok mantığını öğretir.

---

## 65. Bölüm 3 özeti

Bu bölümde UX-MINIMA ile küçük ama anlamlı örnekler kurduk. Başlık ekranı, karakter üretme, tekrar eden çizgi, ölçüm barı, tahmin oyunu, karakter parolası, kalite kontrol, DNA/RNA/protein temsil modelleri, kimyasal çorba ve basit yaşayan hücre modeli gibi konuları gördük.

Bu örneklerin ortak noktası şudur: UX-MINIMA’da her problem önce bellek haritasına dönüşür. Oyun karakteri bir hücre olabilir. DNA bazı bir hücre olabilir. Protein aminoasidi bir hücre olabilir. Kimyasal madde miktarı bir hücre olabilir. Enerji, besin, atık ve stres birer hücre olabilir. Data alanı açıklama metinlerini taşır. Stack geçici hesapları taşır. Döngüler hücrelerin sıfıra gidip gitmemesiyle çalışır. Koşullar flag hücreleriyle kurulur.

Bundan sonraki son bölümde dilin sınırlarını ve olasılıklarını daha eleştirel ele alacağız. Tahmin oyununun daha gelişmiş tasarımını, protein ve RNA dizilimlerinin modellemedeki anlamını, yaşayan hücrelerin soyut simülasyonunu, ezoterik dillerin bilimsel dünyadaki kullanım alanlarını, Brainfuck’e iki komut eklenerek yapılan deney fikrini, stack ve data alanının daha ileri kullanım olanaklarını, UX-MINIMA’nın yeterliliklerini ve eksikliklerini değerlendireceğiz.

**Bölüm 3/4 burada bitti.**

```
```


## Bölüm 4/4 — Sınırlar, Olasılıklar, Ezoterik Diller, BFF Deneyi ve UX-MINIMA’nın Geleceği

### 66. Son bölüme giriş

Bu son bölümde UX-MINIMA x64 V3’e daha geniş açıdan bakacağız. İlk üç bölümde dilin komutlarını, tape modelini, stack kullanımını, string/data alanını, döngüleri, koşulları, basit oyunları, DNA/RNA/protein temsilini ve kimyasal çorba fikrini gördük. Şimdi daha eleştirel davranacağız: Bu dil neye yeter, neye yetmez, nerede öğretici olur, nerede pratik olmaz, bilimsel modelleme için nasıl kullanılabilir, Brainfuck ve türevlerindeki deneyler bize ne anlatır?

UX-MINIMA’nın en önemli değeri şudur: Programcıyı hazır komutlardan soyup hesaplamanın en küçük parçalarıyla karşı karşıya bırakır. Bu yüzden bu dil, “kolay program yazma dili” değil, “programlama düşüncesini derinleştirme dili” olarak görülmelidir.

---

### 67. Gelişmiş tahmin oyunu tasarımı

Bölüm 3’te tek karakterli bir tahmin oyunu yazmıştık. Bu oyunda kullanıcıdan bir karakter alınıyor, `A` karakteriyle karşılaştırılıyor ve doğruysa mesaj yazdırılıyordu.

Basit sürüm:

```text
s1=0,{A harfine bas: }
s2=100,{Dogru tahmin}
p1
,
$0+k65?[
0+++++@
p2
0
]
```

Bu program çalışır ama eksiktir. Yanlış cevap için mesaj yazdırmaz. Ayrıca kullanıcı girdisini bir kez karşılaştırınca stack’teki değer tüketildiği için aynı girdiyi tekrar kullanmak zordur. Bu bize UX-MINIMA’nın temel derslerinden birini gösterir: Eğer bir değer birden fazla kez kullanılacaksa, onu kaybetmeden saklamak gerekir.

Daha sağlam bir tahmin oyunu için bellek planı şöyle olmalıdır:

```text
tape[0] = kullanıcının girdiği karakter
tape[1] = geçici kopya
tape[2] = hedef karakter, örneğin 65
tape[3] = flag
data[0] = başlık mesajı
data[100] = doğru mesajı
data[200] = yanlış mesajı
```

Bu tasarımda kullanıcıdan gelen karakter `tape[0]` hücresinde korunmalıdır. Karşılaştırmalar yapılırken bu değer stack’e gönderilir, ama her karşılaştırmadan sonra tekrar kullanılacaksa değerin tape üzerinde korunması gerekir. Bu nedenle gelişmiş tahmin oyunu, sadece oyun değil, aynı zamanda “veriyi koruma” alıştırmasıdır.

BASIC veya Python’da bu çok kolaydır:

```python
x = input()
if x == "A":
    print("Dogru")
else:
    print("Yanlis")
```

UX-MINIMA’da ise `input`, `karşılaştırma`, `doğru blok`, `yanlış blok`, `flag sıfırlama`, `stack tüketimi` ve `pointer konumu` ayrı ayrı düşünülür. Bu zorluk, dilin eğitim değeridir.

---

### 68. UX-MINIMA’da “yanlış cevap” problemi

Yanlış cevabı anlamanın birkaç yolu vardır. Birinci yol, hedefle eşitliği test etmek ve eşitlik yoksa başka bir yol çalıştırmaktır. Fakat çekirdek UX-MINIMA’da doğrudan boolean `NOT` yoktur. `~` komutu bitwise NOT’tur; 0 değerini 255 yapar, 1 değerini 254 yapar. Bu nedenle `~` doğrudan “değil” anlamında kullanılmaz.

İkinci yol, eşit değil durumunu iki parçaya ayırmaktır:

```text
x < hedef
x > hedef
```

Eğer bu iki durumdan biri doğruysa cevap yanlıştır. Bu, `;` ve `!` komutlarıyla kurulabilir. Ancak her karşılaştırma stack’ten bir değer tükettiği için, `x` değerini tekrar stack’e koymak gerekir. Bu da giriş karakterini tape üzerinde korumayı zorunlu kılar.

Bu yüzden UX-MINIMA’da IF-ELSE benzeri programlar yazarken şu disiplin gerekir:

```text
1. Girdi değerini kaybetme.
2. Her karşılaştırmadan önce gerekli değeri stack’e koy.
3. Karşılaştırma sonucu flag hücresine dönüşür.
4. IF gibi kullanılacak blok sonunda flag’i 0 yap.
5. Pointer’ın hangi hücrede olduğunu unutma.
```

Bu kurallar öğrenilirse tahmin oyunu, parola kontrolü, menü seçimi ve basit karar sistemleri kurulabilir.

---

### 69. Protein ve RNA diziliminin modellenmesi

Protein ve RNA dizileri UX-MINIMA için çok uygun soyutlama alanlarıdır. Çünkü bu diziler zaten sıralı yapılardır. UX-MINIMA’nın tape sistemi de sıralı hücrelerden oluşur.

RNA için örnek kodlama:

```text
A = 1
U = 2
G = 3
C = 4
```

Protein için örnek kodlama:

```text
Met = 5
Ala = 1
Gly = 3
Cys = 2
Stop = 0
```

Bir RNA kodonu olan `AUG` tape üzerinde şöyle tutulabilir:

```text
+k1>+k2>+k3
```

Burada `tape[0] = A`, `tape[1] = U`, `tape[2] = G` gibi düşünülür. Bu şekilde tape, biyolojik bir dizinin yapay temsilidir.

Protein dizisi için:

```text
# Met-Ala-Gly-Cys-Stop
+k5>+k1>+k3>+k2>0
```

Burada `0` stop kodu olarak seçilirse, UX-MINIMA’nın döngü mantığıyla ilginç bir uyum oluşur. Çünkü `[` komutu aktif hücre 0 olduğunda döngüye girmez. Yani 0 değeri hem biyolojik modelde “dur” anlamına gelebilir hem de programlama modelinde döngüyü bitirebilir.

Bu çok öğretici bir bağlantıdır. Gerçek biyolojik süreçler elbette çok daha karmaşıktır. Ama UX-MINIMA ile sıralı biyolojik bilgiyi hücre hücre temsil etmeyi öğrenmek mümkündür.

---

### 70. Motif arama ve kodon tanıma

Bir protein dizisinde belirli bir aminoasidi aramak, aktif hücreyi belirli bir değerle karşılaştırmak demektir. Örneğin Cys kodu 2 ise:

```text
s1=0,{Cys bulundu}
+k2$0+k2?[
p1
0
]
```

Bu örnek doğrudan 2 ile 2’yi karşılaştırır. Gerçek programda pointer protein dizisi üzerinde gezer, her hücreyi 2 ile karşılaştırır ve eşleşme varsa mesaj basar.

Üçlü motif aramak daha zordur. Örneğin RNA’da `AUG` aramak için üç karşılaştırma gerekir:

```text
cell[i]   == 1
cell[i+1] == 2
cell[i+2] == 3
```

Bu üç sonucun hepsi doğruysa motif bulunmuş olur. UX-MINIMA’da bu, üç flag hücresinin AND işlemiyle birleştirilmesi anlamına gelir.

Düşünce planı:

```text
flag0 = birinci baz doğru mu?
flag1 = ikinci baz doğru mu?
flag2 = üçüncü baz doğru mu?
sonuç = flag0 AND flag1 AND flag2
```

Burada `&` komutu kullanılabilir. Fakat `&` stack ile çalıştığı için flagleri stack ve tape arasında dikkatli taşımak gerekir. Bu örnek, UX-MINIMA’nın neden “düşünmeyi öğreten dil” olduğunu çok iyi gösterir.

---

### 71. Yaşayan hücrelerin modellenmesi

Yaşayan bir hücreyi gerçek anlamda modellemek çok zordur. Fakat eğitim amaçlı soyut bir hücre modeli kurulabilir. Tape hücreleri, hücre içindeki bazı büyüklükleri temsil edebilir:

```text
tape[0] = enerji
tape[1] = besin
tape[2] = atık
tape[3] = büyüme
tape[4] = stres
```

Basit kurallar şöyle olabilir:

```text
Besin varsa enerji artsın.
Enerji varsa büyüme artsın.
Atık artarsa stres artsın.
Stres eşik üstündeyse uyarı yazılsın.
Enerji sıfıra düşerse sistem dursun.
```

Bu kuralların her biri UX-MINIMA’da hücre dönüşümü, karşılaştırma veya döngü olarak kurulabilir. Örneğin besinden enerjiye dönüşüm:

```text
# tape[0] = besin
# tape[1] = enerji
+k10[->+<]
```

Bu modelde `besin` 10 birim başlar, her döngüde 1 azalır ve enerji 1 artar. Bu gerçek biyokimya değildir. Fakat “madde akışı”, “stok”, “dönüşüm”, “eşik”, “feedback” gibi kavramları anlamak için güçlü bir soyutlamadır.

UX-MINIMA burada bilimsel hesap makinesi değil, düşünce laboratuvarıdır.

---

### 72. Bilimsel dünyada ezoterik dillerin yeri

Ezoterik programlama dilleri çoğu zaman şaka, sanat, meydan okuma veya zihin egzersizi gibi görülür. Brainfuck bunun en ünlü örneklerinden biridir. Brainfuck, sekiz komuttan oluşan minimal bir dildir; bu komutlar `>`, `<`, `+`, `-`, `.`, `,`, `[`, `]` şeklindedir ve buna rağmen Turing-complete kabul edilir. ([brainfuck.org][1])

Bilimsel açıdan ezoterik dillerin değeri, pratik uygulama geliştirmekten çok, hesaplamanın temel ilkelerini çıplak hale getirmeleridir. Bir dil ne kadar küçülürse, programcı o kadar fazla şeyi kendisi kurmak zorunda kalır. Bu da bellek, kontrol akışı, veri hareketi, simülasyon ve kendi kendini değiştirme gibi konuları daha görünür hale getirir.

Bu yüzden ezoterik diller şu alanlarda yararlı olabilir:

```text
1. Hesaplama kuramı eğitimi
2. Compiler ve interpreter tasarımı
3. Minimal sistemlerde Turing-completeness incelemeleri
4. Yapay yaşam ve self-replication deneyleri
5. Program sentezi ve evrimsel hesaplama
6. Düşük seviyeli bellek ve pointer eğitimi
7. Kod-golf ve algoritmik yaratıcılık
```

UX-MINIMA da bu çizgide düşünülmelidir. Bu dilin amacı Python’un, BASIC’in, C’nin veya uXBasic’in yerini almak değildir. Amacı, hesaplamanın iskeletini görünür hale getirmektir.

---

### 73. Brainfuck’e iki komut eklenen BFF deneyi

2024 tarihli “Computational Life: How Well-formed, Self-replicating Programs Emergence from Simple Interaction” çalışmasında Brainfuck ailesinden genişletilmiş bir dil kullanılmıştır. Çalışmada orijinal Brainfuck’ün sekiz komutlu yapısından hareket edilir; fakat input/output akışları yerine aynı tape üzerinde okuma-yazma yapan, kendi kendini değiştirebilen bir ortam kurulur. Bu genişletilmiş aileye BFF adı verilmiştir. 

Bu deneyde klasik Brainfuck’teki ana pointer’a ek olarak ikinci bir head fikri kullanılır. İki ek komut şunlardır:

```text
{ = ikinci head sola gider
} = ikinci head sağa gider
```

BFF komut setinde `>` ve `<` birinci head’i hareket ettirir, `{` ve `}` ikinci head’i hareket ettirir. `+` ve `-` birinci head’in gösterdiği hücreyi değiştirir. `.` ve `,` ise klasik ekrana yazma ve klavyeden okuma anlamında değil, iki head arasında kopyalama anlamında kullanılır: biri `head0` değerini `head1` konumuna, diğeri `head1` değerini `head0` konumuna taşır. Çalışma, veri ve komutun aynı tape üzerinde bulunduğu, yani programların kendilerini ve komşularını değiştirebildiği bir ortam kullanır. 

BFF’de toplam 10 geçerli talimat vardır. 256 olası byte değerinden yalnızca bu 10 tanesi komut sayılır; diğerleri no-op veya veri gibi davranabilir. Bu nokta UX-MINIMA açısından çok önemlidir. Çünkü bizim 64 KB tape/data/stack tasarımımızda da veri ve komut ilişkisini düşünmek mümkündür; fakat UX-MINIMA V3 şu an güvenli tarafta kalır ve komut ile data’yı ayrı kavramlar olarak ele alır.

---

### 74. BFF deneyinin ortamı

BFF deneyinde birçok küçük program rastgele başlatılır. Tipik “primordial soup” simülasyonlarında programlar 64 byte uzunlukta diziler olarak düşünülür. Programlar rastgele çiftler halinde birleştirilir, çalıştırılır, sonra tekrar iki parçaya ayrılarak ortama geri konur. Bu işlem sırasında programlar birbirlerinin içeriğini değiştirebilir. Makaledeki model, bu etkileşimi kimyasal reaksiyon gibi yorumlar: iki program etkileşir ve iki yeni program haline gelir. 

Bu fikir UX-MINIMA açısından çok verimlidir. Çünkü bizim “kimyasal çorba” düşüncemizle doğrudan bağ kurar. Tape hücreleri madde miktarı olabilir; program parçaları ise etkileşen moleküler türler gibi düşünülebilir. Elbette bu biyolojik gerçeklik değildir, ama soyut yapay yaşam modelidir.

BFF deneyinde açık bir fitness fonksiyonu yoktur. Yani sisteme “şunu seç, bunu ödüllendir” denmez. Programlar yalnızca etkileşir, kendi kendilerini ve komşularını değiştirir. Buna rağmen bazı koşullarda self-replicator benzeri yapılar ortaya çıkabilir. Çalışmanın önemli iddiası, bu yapıların çoğu durumda yalnızca rastgele mutasyonla değil, self-modification ve etkileşim dinamikleriyle de ortaya çıkabilmesidir. 

---

### 75. Deneyde gözlenen sonuçlar

BFF deneylerinde bazı koşullarda self-replicator yapılarının ortaya çıktığı gözlenmiştir. Makale, belirli parametrelerde 16.000 epoch içinde koşulların yaklaşık yüzde 40’ında self-replicator geçişlerinin görüldüğünü bildirir. Ayrıca mutasyon oranı arttıkça bu geçişin hızlanabildiği, fakat mutasyon olmadan da benzer geçişlerin oluşabildiği belirtilir. 

Bu sonuçların UX-MINIMA için anlamı şudur: Çok küçük komut setleriyle bile, eğer programlar veriyle aynı alanda bulunur, birbirlerini değiştirebilir ve etkileşime girebilirse, karmaşık dinamikler doğabilir. Bu, bizim UX-MINIMA’da hemen uygulamamız gereken bir şey değildir. Ama dilin geleceği açısından ufuk açıcıdır.

UX-MINIMA V3 şu anda güvenli ve anlaşılır bir compiler dili olarak tasarlanmıştır. Fakat ileride ayrı bir deneysel mod düşünülürse, “programlar data alanında saklanır, tape üzerinde yorumlanır, kendini değiştirebilir” gibi bir yapay yaşam modu kurulabilir. Bu ana compiler’dan ayrı tutulmalıdır; çünkü güvenlik, debug ve kontrol çok zorlaşır.

---

### 76. BFF kod motifleri ve UX-MINIMA’ya etkisi

BFF çalışmasında kopyalama davranışları için kısa motifler önemlidir. Makalede örneklenen replikatör davranışlarında `[,}<]` ve `[<,}]` gibi küçük döngü yapıları görülür; bu motiflerde head hareketleri ve kopyalama işlemleri birlikte çalışarak bir bölgedeki bilgiyi başka bölgeye taşıyabilir. 

Bu motifleri UX-MINIMA için doğrudan kopyalamak doğru olmaz, çünkü bizim `.` ve `,` komutlarımız hâlâ I/O anlamındadır; `.` karakter basar, `,` karakter okur. BFF’de ise bu komutlar head’ler arası kopyalama anlamına getirilmiştir. Fakat fikir şudur: İkinci pointer/head eklendiğinde, tape üzerinde kopyalama ve kendini çoğaltma davranışları çok daha doğal hale gelir.

UX-MINIMA V3’te `{` ve `}` komutları ikinci head hareketi değil, shift left/right olarak tasarlanmıştır. Bu nedenle UX-MINIMA V3, BFF değildir. Ancak BFF deneyinden şu ders alınabilir: Eğer bir gün UX-MINIMA’nın yapay yaşam sürümü tasarlanırsa, ikinci head veya read/write head sistemi ayrı bir mod olarak düşünülebilir.

Örneğin UXM-Life gibi ayrı bir deneysel modda şu komutlar düşünülebilir:

```text
> < = ana head hareketi
{ } = ikinci head hareketi
.   = ana head değerini ikinci head konumuna kopyala
,   = ikinci head değerini ana head konumuna kopyala
```

Ama bu, mevcut UX-MINIMA V3 compiler’ın komutlarıyla karıştırılmamalıdır. Çünkü mevcut V3’te `{` ve `}` shift işlemidir.

---

### 77. BFF deneyinin örnek mantığını kendi kodumuzla göstermek

Aşağıdaki kod, BFF makalesindeki kodun birebir kopyası değil; fikri anlatmak için yazılmış temsili bir modeldir.

BFF benzeri iki-head kopyalama düşüncesi:

```text
# Bu UX-MINIMA V3 kodu degil, BFF fikrini anlatan temsili kod
# head0 kaynak üzerinde, head1 hedef üzerinde
[
,
}
<
]
```

Bu temsili fikirde `,` bir head’den diğerine kopyalama gibi düşünülür, `}` ikinci head’i ilerletir, `<` birinci head’i geri alır veya kaynak üzerinde hareket eder. Bu tarz küçük döngüler, uygun ortamda bir parçanın başka yere yazılmasına neden olabilir.

UX-MINIMA V3’te aynı fikri daha güvenli ve açık şekilde düşünmek istersek, normal tape hücreleri arasında taşıma patternleri kullanırız:

```text
[->+<]
```

Bu pattern aktif hücredeki değeri sağdaki hücreye taşır ve aktif hücreyi sıfırlar. Bu self-replication değildir ama madde/değer transferinin çekirdeğidir.

Daha güçlü kopyalama için:

```text
[->+>+<<]>>[-<<+>>]<<
```

Bu yapı değeri iki yere dağıtıp bir kopyayla kaynağı geri kurma fikrini gösterir. BFF’de bu tür kopyalama kendini değiştiren program ortamında evrimsel davranışlara yol açabilir. UX-MINIMA’da ise bu, kontrollü bellek işlemi olarak kalır.

---

### 78. Stack’in ileri kullanım olanakları

Stack, UX-MINIMA’da sadece push/pop için değil, düşünce olarak birçok yapının temelidir. Karşılaştırmalar stack ile çalışır. Bitwise ikili işlemler stack ile çalışır. Geçici değerler stack ile saklanır. Hatta küçük tersleme işlemleri stack ile yapılabilir.

Örneğin karakterleri ters sırayla basmak:

```text
+k65$0+k66$0+k67$%.%.%.
```

Bu kod `CBA` basar. Çünkü stack LIFO’dur.

Eğer `ABC` basmak istiyorsan değerleri ters sırada stack’e atarsın:

```text
+k67$0+k66$0+k65$%.%.%.
```

Stack’in ileri kullanımı için şu fikirler önemlidir:

```text
1. Ters çevirme
2. Geçici operand saklama
3. Karşılaştırma
4. Bit maskesi işlemleri
5. Mini ifade değerlendirme
6. Basit çağrı/geri dönüş modeli için deneysel temel
```

Fakat stack uzun süreli veri saklama için uygun değildir. Stack’te ne olduğunu bilmiyorsan program bozulur. Stack görünmezdir; tape gibi yan yana gözlenmez. Bu yüzden stack kullanımında yorum ve disiplin şarttır.

---

### 79. Data alanının ileri kullanım olanakları

Data alanı başlangıçta stringler için düşünülmüştür. Fakat daha geniş tasarımda data alanı şu amaçlarla kullanılabilir:

```text
1. Sabit mesajlar
2. ASCII ekran şablonları
3. DNA/RNA/protein dizisi tabloları
4. Deney parametre açıklamaları
5. Menü metinleri
6. Model başlangıç verileri
7. Sabit katsayılar
8. Hata mesajları
```

Örneğin bir biyolojik modelde data alanı açıklama metinlerini taşıyabilir:

```text
s1=0,{AUG start kodonu bulundu}
s2=100,{Stop kodonu bulundu}
s3=200,{Cys motifi bulundu}
```

Tape ise modelin aktif durumunu taşır. Stack ise hesap sırasında kullanılır.

Bu ayrım programı daha temiz hale getirir:

```text
tape = durum
stack = geçici işlem
data = sabit bilgi ve string
```

Bu üçlü ayrım UX-MINIMA V3’ün en güçlü tasarım noktalarından biridir.

---

### 80. UX-MINIMA’nın olasılıkları

UX-MINIMA x64 V3 ile yapılabilecekler şunlardır:

```text
1. Tape tabanlı düşük seviye programlama eğitimi
2. Pointer ve bellek yönetimi öğretimi
3. Stack mantığı öğretimi
4. x64 NASM codegen deneyleri
5. Pattern tabanlı compiler optimizasyonu
6. ASCII tabanlı oyun ve ekran denemeleri
7. Kimyasal dönüşüm modelleri
8. DNA/RNA/protein dizi temsilleri
9. Basit karar sistemleri
10. Bar grafik tabanlı bilimsel gösterimler
11. Brainfuck türevi dillerin anlaşılması
12. Runtime/compiler ayrımını öğretmek
```

Dil özellikle compiler yazmak isteyenler için değerlidir. Çünkü aynı komut seti farklı şekillerde derlenebilir: doğrudan emitter ile, pattern-action sistemiyle veya DATA tabanlı pattern-ASM şablonlarıyla. Bu, compiler mimarisini öğrenmek için harika bir laboratuvar oluşturur.

---

### 81. UX-MINIMA’nın sınırları

UX-MINIMA’nın sınırlarını dürüstçe bilmek gerekir. Bu dil pratik uygulama geliştirmek için tasarlanmamıştır. Büyük programlarda okunabilirlik hızla düşer. Pointer takibi zorlaşır. Stack hataları kolay oluşur. Sayı yazdırma çekirdekte doğal değildir. String input zordur. Fonksiyon, prosedür, dosya işlemi, grafik, nesne sistemi, modül sistemi gibi yüksek seviye yapılar yoktur.

Başlıca sınırlılıklar:

```text
1. İsimli değişken yok.
2. Doğrudan decimal sayı yazdırma yok.
3. Gerçek IF-ELSE yok, elle kuruluyor.
4. Fonksiyon yok.
5. Dizi var gibi görünse de indeksli erişim yok.
6. Stack görünmez ve hata yapmaya açık.
7. Uzun programlar okunması zor hale gelir.
8. Debug aracı olmadan takip zordur.
9. Bilimsel hesaplama için sınırlıdır.
10. Gerçek biyolojik modelleme için fazla basittir.
```

Bu sınırlılıklar dili değersiz yapmaz. Tam tersine, eğitim amacını netleştirir. UX-MINIMA büyük uygulama dili değil, hesaplama mantığını çıplaklaştıran bir öğretim ve compiler deney dilidir.

---

### 82. UX-MINIMA’nın yeterlilikleri

UX-MINIMA’nın yeterli olduğu alanlar ise oldukça güçlüdür. Bu dil, bir programcının bilgisayarın nasıl düşündüğünü anlamasına yardım eder. Bellek hücresi, pointer, stack, loop, flag, data alanı, assembler çıktı ve runtime çağrısı gibi konuları bir arada gösterir.

UX-MINIMA şu konularda yeterlidir:

```text
1. Küçük programlar
2. ASCII çıktılar
3. Karakter girişleri
4. Basit karar sistemleri
5. Sayaç döngüleri
6. Hücreden hücreye değer taşıma
7. Stack tabanlı karşılaştırma
8. Bitwise işlem eğitimi
9. Pattern optimizasyonu
10. x64 ASM üretim mantığı
```

Bu dil, özellikle “compiler nasıl çalışır?” sorusuna cevap arayan biri için çok faydalıdır. Çünkü kaynak kod, token, pattern, ASM şablonu, NASM çıktısı ve runtime arasındaki zincir açıkça görülebilir.

---

### 83. UX-MINIMA ile bilimsel modelleme nasıl yapılmalı?

UX-MINIMA ile bilimsel modelleme yapılırken amaç gerçek hesaplama doğruluğu değil, kavramsal temsil olmalıdır. Örneğin gerçek RNA folding, protein motif analizi, kimyasal kinetik veya hücre metabolizması için UX-MINIMA kullanılmaz. Bunun yerine Python, R, C/C++, Julia veya özel biyoinformatik araçları kullanılır.

Ama UX-MINIMA şu soruları öğretmek için kullanılabilir:

```text
Bir dizi nasıl bellekte temsil edilir?
Bir motif nasıl aranır?
Bir eşik nasıl kontrol edilir?
Bir madde miktarı nasıl azaltılır?
Bir ürün miktarı nasıl artırılır?
Bir sistemde durum değişimi nasıl modellenir?
Bir self-replication fikri hesaplama dilinde nasıl temsil edilebilir?
```

Bu yüzden UX-MINIMA bilimsel modellemede “gerçek araç” değil, “kavramsal mikroskop” gibi düşünülmelidir. Karmaşık sistemin en küçük işlem parçalarını gösterir.

---

### 84. Compiler tasarımlarının karşılaştırılması

UX-MINIMA x64 V3 için birkaç compiler mimarisi düşünüldü.

Birinci mimari, tek komut → tek ASM emitter yaklaşımıdır. Bu en basit tasarımdır. Her komut görüldüğünde karşılığı olan ASM satırları basılır. Kolaydır ama optimizasyonu sınırlıdır.

İkinci mimari, pattern → action → emitter yaklaşımıdır. Burada pattern doğrudan ASM saklamaz. Pattern bir action koduna bağlanır. Emitter, hücre tipi ve ayarlara göre doğru ASM üretir. Bu modern ve güvenli bir yaklaşımdır.

Üçüncü mimari, 6502 örneğine benzeyen DATA tabanlı pattern → ASM şablonu yaklaşımıdır. Burada patternler DATA kısmında durur ve karşılarında ASM şablonları vardır. Compiler patterni görünce şablonu açar. Bu model, deneysel compiler için çok uygundur. Çünkü yeni pattern eklemek kolaydır. Dezavantajı ise hücre tipi, register seçimi ve pointer check gibi konularda şablon sisteminin dikkatli tasarlanması gerekmesidir.

Bu üç mimariden sonuncusu, UX-MINIMA’nın 6502 kökenli pattern compiler fikrine en yakın olanıdır. x64 sürümde de bu model korunabilir.

---

### 85. Programcı adayına son tavsiyeler

UX-MINIMA öğrenirken acele etme. Önce `+`, `-`, `>`, `<`, `.`, `,`, `[`, `]` komutlarıyla rahatla. Sonra `0`, `$`, `%`, `?`, `!`, `;` komutlarını ekle. Daha sonra bitwise işlemlere geç. En son string/data ve meta servisleri kullan.

Kod yazmadan önce mutlaka bellek planı yap:

```text
tape[0] = ne?
tape[1] = ne?
tape[2] = geçici mi?
stack’te hangi sırayla ne olacak?
data alanında hangi stringler olacak?
pointer döngü sonunda nereye dönecek?
```

Her döngüde şunu sor:

```text
Bu döngü bitecek mi?
Aktif hücre doğru hücre mi?
Sayaç azalıyor mu?
```

Her stack kullanımında şunu sor:

```text
Stack’e ne attım?
Hangi sırayla geri alacağım?
Bu komut stack’ten değer tüketiyor mu?
```

Her string kullanımında şunu sor:

```text
Data alanında çakışma var mı?
String başlangıç hücreleri yeterince ayrık mı?
```

Bu disiplinleri kazanırsan UX-MINIMA sana sadece bu dili değil, bütün düşük seviyeli programlamanın temelini öğretir.

---

### 86. Sonuç: UX-MINIMA neden değerli?

UX-MINIMA x64 V3, büyük ve konforlu bir dil değildir. Ama çok öğretici bir dildir. Bu dil, programlamanın yüksek seviyeli kabuğunu kaldırır ve seni bellek, pointer, stack, flag, döngü ve runtime kavramlarıyla baş başa bırakır.

BASIC ve Python sana “ne yapmak istediğini” kolayca yazdırır. UX-MINIMA ise “bilgisayarın bunu en küçük adımlarla nasıl yapabileceğini” düşündürür.

Bu yüzden UX-MINIMA’nın değeri şuradadır:

```text
Programcıya hesaplamanın kemik yapısını gösterir.
Compiler tasarımını öğretir.
Assembly üretimini görünür yapar.
Bellek modelini sezdirir.
Bilimsel ve biyolojik sistemlerin soyut temsilini düşündürür.
Ezoterik dillerin neden sadece şaka değil, aynı zamanda düşünce aracı olabileceğini gösterir.
```

Bir gün daha gelişmiş bir uXBasic, pdsX veya başka bir compiler yazarken, UX-MINIMA’da öğrendiğin şeyler arka planda çalışır. Çünkü her büyük dilin altında aynı temel gerçekler vardır: bellek, değer, hareket, karşılaştırma, döngü, giriş, çıkış ve dönüşüm.

UX-MINIMA küçük bir dildir; ama doğru bakılırsa büyük dillerin içindeki küçük makineyi gösterir.

---

## pck.md tamamlandı

Bu dört bölümden oluşan “Programcı Adayının Cep Kitabı”, UX-MINIMA x64 V3’ün temel komutlarını, bellek modelini, stack ve data kullanımını, meta komutlarını, kısaltılmış komutları, döngü ve koşul tasarımlarını, oyun örneklerini, DNA/RNA/protein modelleme fikirlerini, bilimsel modelleme yaklaşımını, BFF deneyini, dilin sınırlarını ve olasılıklarını anlattı.

Bu kitabın en kısa özeti şudur:

```text
UX-MINIMA’da program yazmak, değişken adı yazmak değil, bellek üzerinde düşünmektir.
```

[1]: https://brainfuck.org/brainfuck.html?utm_source=chatgpt.com "Yet another brainfuck reference."


# Ek Bölüm — UX-MINIMA x64 V3 İçin Pratik Tablolar, Aritmetik Rutinler, Dallanma Sorunu ve V3.1 Tasarım Notları

## 1. Bu ek bölüm neden gerekli?

İlk dört bölümde UX-MINIMA x64 V3’ün temel dil mantığını, tape/stack/data modelini, komutları, string kullanımını, döngüleri, koşul kurmayı, biyolojik ve kimyasal modelleme fikirlerini anlattık. Fakat okurken ortaya çıkan çok önemli bir gerçek var: Dilin çekirdeği programlamanın atomik parçalarını gösteriyor ama bazı pratik işler için ek tasarım gerekiyor.

Özellikle şu konular mevcut çekirdekte zor veya eksiktir:

```text
1. Ekrana sayı yazdırma
2. Klavyeden çok basamaklı sayı alma
3. İki sayıyı doğrudan çarpma
4. İki sayıyı doğrudan bölme
5. Bölme kalanını bulma
6. Sin, cos, tan gibi fonksiyonlar
7. Veri tablosundan sayısal veri okuma
8. Liste sıralama
9. Büyük/küçük karşılaştırmaya göre dallanma
10. Label, jump, goto veya yakın/uzak branch sistemi

## ek 2. ASCII tablosu

UX-MINIMA’da . komutu aktif hücredeki değeri karakter olarak basar. Bu yüzden ASCII tablosunu bilmek çok önemlidir. Örneğin aktif hücre 65 ise . komutu ekrana A basar. Aktif hücre 48 ise 0 karakteri basılır.

En çok kullanılan ASCII değerleri şunlardır:

```text
Değer  Karakter  Anlam
0      NUL       String sonu / boş karakter
7      BEL       Uyarı sesi
8      BS        Backspace
9      TAB       Sekme
10     LF        Yeni satır
13     CR        Satır başı
32     SPACE     Boşluk
33     !         Ünlem
34     "         Çift tırnak
35     #         Kare işareti
36     $         Dolar
37     %         Yüzde
38     &         Ampersand
39     '         Tek tırnak
40     (         Aç parantez
41     )         Kapa parantez
42     *         Yıldız
43     +         Artı
44     ,         Virgül
45     -         Eksi
46     .         Nokta
47     /         Bölü
48     0         Rakam 0
49     1         Rakam 1
50     2         Rakam 2
51     3         Rakam 3
52     4         Rakam 4
53     5         Rakam 5
54     6         Rakam 6
55     7         Rakam 7
56     8         Rakam 8
57     9         Rakam 9
58     :         İki nokta
59     ;         Noktalı virgül
60     <         Küçüktür
61     =         Eşittir
62     >         Büyüktür
63     ?         Soru işareti
64     @         At işareti
65     A
66     B
67     C
68     D
69     E
70     F
71     G
72     H
73     I
74     J
75     K
76     L
77     M
78     N
79     O
80     P
81     Q
82     R
83     S
84     T
85     U
86     V
87     W
88     X
89     Y
90     Z
91     [
92     \
93     ]
94     ^
95     _
96     `
97     a
98     b
99     c
100    d
101    e
102    f
103    g
104    h
105    i
106    j
107    k
108    l
109    m
110    n
111    o
112    p
113    q
114    r
115    s
116    t
117    u
118    v
119    w
120    x
121    y
122    z
123    {
124    |
125    }
126    ~
127    DEL       Silme karakteri
``` 