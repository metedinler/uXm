

Mete abi, başladım ve ilk çalışan VS Code eklentisi paketini hazırladım:

[uxminima-vscode.zip](sandbox:/mnt/data/uxminima-vscode.zip)

İçinde şunlar var:

```text
uxminima-vscode/
├─ package.json
├─ tsconfig.json
├─ language-configuration.json
├─ syntaxes/uxm.tmLanguage.json
├─ snippets/uxm.code-snippets
├─ src/
│  ├─ extension.ts
│  ├─ diagnostics.ts
│  ├─ toolchain.ts
│  ├─ traceReader.ts
│  ├─ uxmInterpreter.ts
│  ├─ metaServices.ts
│  └─ views/memoryView.ts
├─ docs/
│  ├─ UXM_LANGUAGE_SPEC.md
│  ├─ UXM_META_SERVICES.md
│  ├─ UXM_MEMORY_MODEL.md
│  ├─ UXM_TRACE_FORMAT.md
│  ├─ UXM_IDE_PROTOCOL.md
│  └─ UXM_EXAMPLES.md
├─ .github/copilot-instructions.md
├─ tools/README_TOOLCHAIN.md
└─ examples/
   ├─ fifo_watch.uxm
   └─ data_sort.uxm
```

Bu ilk paket şu işleri yapıyor:

```text
.uxm dosyalarını tanır
syntax highlighting yapar
snippet verir
hatalı boşluk/adresleme/macro/meta uyarısı verir
@ meta servisleri için hover açıklaması verir
internal trace çalıştırır
Tape / Stack / FIFO / Data izleme paneli açar
UIR / OPT / native build komutlarını toolchain üzerinden çağırır
Copilot için proje talimat dosyası içerir
```

Kurulum:

```bat
cd uxminima-vscode
npm install
npm run compile
code .
```

Sonra VS Code içinde `F5` ile Extension Development Host açılır.

Denemek için:

```text
examples/fifo_watch.uxm
```

dosyasını aç ve Command Palette’ten çalıştır:

```text
UX-MINIMA: Internal Trace & Memory Watch
```

Bu komut, daha toolchain EXE’lerine gerek kalmadan TypeScript içindeki hafif UXM interpreter ile çalışır ve şu panelleri gösterir:

```text
Tape Window
Stack
FIFO
Data Non-Zero
Flags / Status
Output
```

Native toolchain için daha sonra şu dosyaları `tools/` klasörüne koyacağız veya VS Code Settings’ten yollarını göstereceğiz:

```text
uxm31_full_tool.exe
uxm31_compiler_full.exe
uxm31_runtime_fb_full.bas
nasm.exe
fbc.exe
```

Bu paket bizim UX-MINIMA IDE’nin VS Code temelidir.


Mete abi, UX-MINIMA V3.1 için en doğru floating point sistemi **binary IEEE-754 taklidi** değil; **decimal floating / big-decimal** sistemi olmalı. Çünkü sen `.dan sonra 16 veya 32 hane` istiyorsun. Bu, bilimsel hesap, tablo, sinüs tablosu, kimyasal oran, DNA/protein modelleme gibi işlerde daha anlaşılır olur.

Aşağıdaki sistemi **UX-FP V1** diye adlandıralım.

---

# UX-FP V1: UX-MINIMA Decimal Floating Point Sistemi

Temel fikir şudur:

```text
Sayı = sign × mantissa × 10^exponent
```

Yani sayı üç parçadan oluşur:

```text
sign      : sayı pozitif mi negatif mi?
mantissa  : asıl rakam dizisi
exponent  : virgülün / noktanın yeri
```

Örnek:

```text
123.456
```

şu şekilde düşünülebilir:

```text
sign      = +
mantissa  = 123456
exponent  = -3
```

Çünkü:

```text
123456 × 10^-3 = 123.456
```

16 hane veya 32 hane hassasiyet istediğimizde mantissa’yı yeterince uzun tutarız.

---

## 1. Neden decimal floating?

Normal bilgisayar float sistemi genellikle binary çalışır. Yani 0.1 gibi sayılar bilgisayarda tam temsil edilemeyebilir. Bizim UX-MINIMA’da hedefimiz daha öğretici, daha kontrol edilebilir, daha açık bir sistem olduğu için decimal mantık daha uygun.

Örneğin:

```text
0.1 + 0.2 = 0.3
```

bekleriz. Binary floating point’te bu bazen:

```text
0.30000000000000004
```

gibi görünebilir. UX-FP decimal sistemde bunu kontrol ederiz.

---

# 2. Hücre düzeni

UX-FP sayıları **Data alanında blok** olarak tutulacak.

Her floating sayı bir data bloğudur.

Önerilen FP blok yapısı:

```text
D:BASE+0   magic değer       = 70   # 'F'
D:BASE+1   precision mode    = 16 veya 32
D:BASE+2   sign              = 0 pozitif, 1 negatif
D:BASE+3   exponent sign     = 0 pozitif, 1 negatif
D:BASE+4   exponent abs      = üs mutlak değeri
D:BASE+5   used limbs        = kullanılan mantissa parça sayısı
D:BASE+6   status            = hata / normalizasyon durumu
D:BASE+7   reserved
D:BASE+8   mantissa limb 0
D:BASE+9   mantissa limb 1
D:BASE+10  mantissa limb 2
...
```

Burada mantissa **base-100** şeklinde saklanacak.

Yani her hücre 0–99 arası iki decimal rakam tutar.

Örnek:

```text
12345678
```

mantissa olarak şu parçalara ayrılır:

```text
12 34 56 78
```

Ama aritmetik kolay olsun diye bellekte **little-endian** tutmak daha iyi:

```text
D:BASE+8   = 78
D:BASE+9   = 56
D:BASE+10  = 34
D:BASE+11  = 12
```

Yani en küçük basamak önce gelir. Toplama, çıkarma, çarpma böyle daha kolay olur.

---

# 3. FP16 ve FP32 blok boyutu

## FP16

Virgülden sonra 16 decimal hane için en az 16 hane gerekir. Base-100 kullandığımız için:

```text
16 decimal hane = 8 limb
```

Ama sadece virgülden sonraki değil, tam kısım için de yer gerekir. Bu yüzden FP16 için mantissa’yı 16 limb yapmak daha mantıklı.

```text
16 limb × 2 rakam = 32 decimal rakam kapasitesi
```

FP16 blok:

```text
Header  = 8 hücre
Mantissa= 16 hücre
Toplam  = 24 hücre
```

Yani:

```text
FP16 blok boyutu = 24 data hücresi
```

## FP32

Virgülden sonra 32 decimal hane için:

```text
32 decimal hane = 16 limb
```

Tam kısma da yer açmak için mantissa’yı 32 limb yapalım.

```text
32 limb × 2 rakam = 64 decimal rakam kapasitesi
```

FP32 blok:

```text
Header  = 8 hücre
Mantissa= 32 hücre
Toplam  = 40 hücre
```

Yani:

```text
FP32 blok boyutu = 40 data hücresi
```

---

# 4. Bellekte örnek sayı

Sayı:

```text
-123.4567
```

Şöyle saklanır:

```text
sign      = 1
mantissa  = 1234567
exponent  = -4
```

Çünkü:

```text
1234567 × 10^-4 = 123.4567
```

Data bloğu:

```text
D:100+0  = 70       # magic
D:100+1  = 16       # FP16 mode
D:100+2  = 1        # negatif
D:100+3  = 1        # exponent negatif
D:100+4  = 4        # exponent abs
D:100+5  = 4        # used limbs
D:100+6  = 0        # status OK
D:100+7  = 0        # reserved
D:100+8  = 67
D:100+9  = 45
D:100+10 = 23
D:100+11 = 1
```

Çünkü mantissa little-endian base-100:

```text
1234567 = 1 | 23 | 45 | 67
```

Bellekte ters:

```text
67, 45, 23, 1
```

---

# 5. UX-MINIMA macro frame düzeni

UX-FP macro’ları mevcut V3.1 meta frame düzenini kullanmalı.

Genel frame:

```text
T-2 = hedef FP blok adresi
T-1 = A FP blok adresi
T   = B FP blok adresi veya servis / mod değeri
T+1 = sonuç / status
```

Bazı tek operandlı işlemler için:

```text
T-2 = hedef FP blok adresi
T-1 = kaynak FP blok adresi
T   = opsiyonel parametre
T+1 = status
```

Örnek:

```text
>>
0(T-2)+k200   # hedef FP blok D:200
0(T-1)+k100   # A sayısı D:100
0(T)+k140     # B sayısı D:140
@210          # FP_ADD
```

---

# 6. UX-FP macro numara alanı

UX-MINIMA’da `m128..m255` kullanıcı macro alanıydı. Floating point kütüphanesini şu aralıkta tanımlayalım:

```text
m200..m239  UX-FP decimal floating point macro alanı
```

Önerilen macro listesi:

```text
m200  FP_INIT16
m201  FP_INIT32
m202  FP_CLEAR
m203  FP_COPY
m204  FP_NORMALIZE
m205  FP_SET_SIGN
m206  FP_SET_EXP
m207  FP_SET_LIMB
m208  FP_GET_LIMB
m209  FP_PRINT_RAW

m210  FP_ADD
m211  FP_SUB
m212  FP_MUL
m213  FP_DIV
m214  FP_COMPARE
m215  FP_ABS
m216  FP_NEG
m217  FP_ROUND16
m218  FP_ROUND32
m219  FP_TRUNC

m220  FP_FROM_INT
m221  FP_FROM_DEC_STRING
m222  FP_TO_DEC_STRING
m223  FP_PRINT_DEC
m224  FP_SCALE10
m225  FP_ALIGN_EXP
m226  FP_SHIFT_LEFT_DEC
m227  FP_SHIFT_RIGHT_DEC

m230  FP_SIN_TABLE
m231  FP_COS_TABLE
m232  FP_SQRT
m233  FP_HYPOT
m234  FP_POW_INT
```

Burada önemli karar şudur:

**Temel FP işlemleri saf UXM macro ile yapılabilir**, ama 32 hane division, sqrt, sin gibi işlemler çok uzun olur. Bu yüzden iki katmanlı tasarım en iyisi:

```text
Katman 1: UXM macro API
Katman 2: Host meta servis hızlandırıcıları
```

Yani kullanıcı `@210` veya `m210` mantığıyla FP_ADD çağırır. İlk sürümde macro saf UXM olabilir; hızlı sürümde aynı çağrı FreeBASIC runtime meta servisine bağlanabilir.

---

# 7. FP status kodları

Her FP blok içinde `BASE+6` status alanı olacak.

```text
0   OK
1   normalize gerekli
2   mantissa overflow
3   exponent overflow
4   division by zero
5   invalid number
6   precision loss
7   rounded
8   negative zero cleaned
9   underflow
10  NaN benzeri geçersiz durum
```

UX-MINIMA genel status byte ile karışmasın diye FP status kendi blok header’ında tutulur.

---

# 8. Normalizasyon mantığı

Normalizasyonun amacı şudur:

```text
Mantissa başında gereksiz sıfır kalmasın.
Exponent buna göre ayarlansın.
```

Örnek:

```text
mantissa = 00123456
exponent = -4
```

normalleştirilir:

```text
mantissa = 123456
exponent = -4
```

Başta sıfır limb varsa silinir.

Little-endian tutulduğu için en büyük limb en sondadır. O yüzden normalize işlemi mantissa’nın sonundan başlar.

Pseudo mantık:

```text
while used_limbs > 1 and limb[used_limbs-1] = 0:
    used_limbs--
```

Eğer bütün mantissa sıfırsa:

```text
sign = 0
exponent = 0
used_limbs = 1
limb[0] = 0
```

---

# 9. Toplama mantığı

FP_ADD için iki sayı toplanmadan önce exponent eşitlenir.

Örnek:

```text
A = 12345 × 10^-2  = 123.45
B = 678   × 10^-1  = 67.8
```

Exponentler:

```text
A exponent = -2
B exponent = -1
```

Aynı exponent’e getirmek gerekir:

```text
B = 6780 × 10^-2
```

Sonra mantissa toplanır:

```text
12345 + 6780 = 19125
```

Sonuç:

```text
19125 × 10^-2 = 191.25
```

UX-FP ADD adımları:

```text
1. A ve B exponent oku.
2. Küçük exponent’i hedef exponent yap.
3. Büyük exponentli sayının mantissa’sını 10 fark kadar kaydır.
4. Sign aynıysa mantissa topla.
5. Sign farklıysa büyük mutlak değerden küçüğü çıkar.
6. Sonucu normalize et.
7. Precision 16/32 sınırını uygula.
```

---

# 10. Çarpma mantığı

Çarpma daha nettir.

```text
A = mantA × 10^expA
B = mantB × 10^expB
```

Sonuç:

```text
R = mantA × mantB × 10^(expA + expB)
```

Yani:

```text
result_sign = signA XOR signB
result_exp  = expA + expB
result_mant = mantA * mantB
```

Mantissa base-100 limb çarpımı klasik uzun çarpma ile yapılır.

Pseudo:

```text
for i = 0 to usedA-1
    carry = 0
    for j = 0 to usedB-1
        temp = result[i+j] + A[i] * B[j] + carry
        result[i+j] = temp mod 100
        carry = temp / 100
    next
    result[i+usedB] += carry
next
```

Bu işlem UXM macro ile yazılabilir çünkü her limb 0–99 arasıdır.

---

# 11. Bölme mantığı

Bölme en zor kısımdır.

Temel formül:

```text
A / B = mantA / mantB × 10^(expA - expB)
```

Ama decimal hassasiyet için mantA’yı önce büyütürüz.

FP16 için:

```text
mantA_scaled = mantA × 10^16
```

FP32 için:

```text
mantA_scaled = mantA × 10^32
```

Sonra integer division yapılır:

```text
result_mant = mantA_scaled / mantB
result_exp = expA - expB - scale
```

Yani division sistemi aslında büyük integer bölmedir.

İlk aşamada division macro çok uzun olur. Bu yüzden önerim:

```text
m213 FP_DIV
```

iki modda çalışsın:

```text
safe macro mode:
    yavaş ama öğretici long division

host accelerated mode:
    FreeBASIC runtime meta servisi ile hızlı big-decimal division
```

---

# 12. 16 hane / 32 hane seçimi

Her FP blokta precision tutulur:

```text
D:BASE+1 = 16 veya 32
```

Ama bu “toplam mantissa hane sayısı” değil, “virgülden sonra hedef hane” olarak yorumlanmalı.

Böylece:

```text
FP16 = .dan sonra 16 hane
FP32 = .dan sonra 32 hane
```

Round işlemi:

```text
m217 FP_ROUND16
m218 FP_ROUND32
```

Virgülden sonra fazla hane varsa yuvarlar.

Örnek:

```text
1.234567890123456789
```

FP16:

```text
1.2345678901234568
```

FP32:

```text
1.23456789012345678900000000000000
```

---

# 13. FP blok örnekleri

## A = 12.34

```text
mantissa = 1234
exponent = -2
```

D:100 bloğu:

```text
D:100 = 70
D:101 = 16
D:102 = 0
D:103 = 1
D:104 = 2
D:105 = 2
D:106 = 0
D:107 = 0
D:108 = 34
D:109 = 12
```

## B = 5.6

```text
mantissa = 56
exponent = -1
```

D:140 bloğu:

```text
D:140 = 70
D:141 = 16
D:142 = 0
D:143 = 1
D:144 = 1
D:145 = 1
D:146 = 0
D:147 = 0
D:148 = 56
```

## R = A + B

```text
12.34 + 5.6 = 17.94
```

R bloğu D:180:

```text
mantissa = 1794
exponent = -2
limbs = 94, 17
```

---

# 14. UXM kullanım örneği

Aşağıdaki kullanımda sayılar hazır data bloklarında var kabul edilir.

```text
# FP ADD örneği
# A = D:100
# B = D:140
# R = D:180

>>
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
```

Burada:

```text
T-2 = result base
T-1 = A base
T   = B base
@210 = FP_ADD
```

---

# 15. UX-FP için meta servis önerisi

Mevcut runtime’da `@128..@255` kullanıcı macro alanı olarak düşünülmüştü. Native taraf macro’ları inline açıyor. Ama floating point için daha iyi tasarım şu:

```text
@200..@239 host accelerated floating point servisleri
m200..m239 pure UXM fallback macro’ları
```

Yani:

```text
@210 = hızlı FP_ADD
m210 = saf UXM FP_ADD macro
```

Eğer runtime `@210` destekliyorsa onu kullanırız. Desteklemiyorsa compiler macro olarak `m210` açar.

Bu iki seviyeli sistem çok iyi olur:

```text
Eğitim için: saf UXM macro
Performans için: FreeBASIC runtime meta servis
```

---

# 16. UX-FP servis tablosu

```text
@200 / m200   FP_INIT16
@201 / m201   FP_INIT32
@202 / m202   FP_CLEAR
@203 / m203   FP_COPY
@204 / m204   FP_NORMALIZE
@205 / m205   FP_SET_SIGN
@206 / m206   FP_SET_EXP
@207 / m207   FP_SET_LIMB
@208 / m208   FP_GET_LIMB
@209 / m209   FP_PRINT_RAW

@210 / m210   FP_ADD
@211 / m211   FP_SUB
@212 / m212   FP_MUL
@213 / m213   FP_DIV
@214 / m214   FP_COMPARE
@215 / m215   FP_ABS
@216 / m216   FP_NEG
@217 / m217   FP_ROUND16
@218 / m218   FP_ROUND32
@219 / m219   FP_TRUNC

@220 / m220   FP_FROM_INT
@221 / m221   FP_FROM_DEC_STRING
@222 / m222   FP_TO_DEC_STRING
@223 / m223   FP_PRINT_DEC
@224 / m224   FP_SCALE10
@225 / m225   FP_ALIGN_EXP
@226 / m226   FP_SHIFT_LEFT_DEC
@227 / m227   FP_SHIFT_RIGHT_DEC

@230 / m230   FP_SQRT
@231 / m231   FP_HYPOT
@232 / m232   FP_SIN
@233 / m233   FP_COS
@234 / m234   FP_TAN
```

---

# 17. Data alanında FP kütüphane düzeni

Önerilen standart bloklar:

```text
D:0..99       sabitler ve geçici alan
D:100..139    FP A
D:140..179    FP B
D:180..219    FP R
D:220..259    FP TMP1
D:260..299    FP TMP2
D:300..399    string buffer
```

Örneğin:

```text
FP16 A   = D:100
FP16 B   = D:140
FP16 R   = D:180
FP32 A   = D:500
FP32 B   = D:540
FP32 R   = D:580
```

---

# 18. Makro olarak gerçek başlangıç taslağı

UXM içinde doğrudan şu macro tanımlanabilir:

```text
# UX-FP V1 küçük başlangıç kütüphanesi

# m200: FP_INIT16
# T-2 = base
m200={
0(D:0)
}

# m202: FP_CLEAR
# T-2 = base
m202={
# Bu macro gerçek sürümde D:base+0..base+23 aralığını temizlemeli.
# UXM V3.1 doğrudan D:(T-2+n) adreslemeyi desteklemediği için
# bunu host meta servis veya gelişmiş indirect data addressing ile yapmak daha doğru.
}

# m216: FP_NEG
# T-1 = source base
# T-2 = dest base
m216={
# sign flip macro
}
```

Burada kritik bir nokta var Mete abi:

Mevcut V3.1 adresleme sisteminde:

```text
(D:N)
```

mutlak data adresi destekleniyor. Ama:

```text
(D:T+N)
```

gibi dinamik data adresleme henüz yok.

Floating point macro’ları için bu gerekir.

Bu yüzden FP sistemiyle birlikte şu adresleme modunu eklemek çok iyi olur:

```text
(D@T)       T hücresindeki değeri data adresi kabul et
(D@T+N)     T hücresindeki değer + N data adresi
(D@T- N)    T hücresindeki değer - N data adresi
```

Veya daha temiz:

```text
(D* T)
(D* T+8)
```

Ama sen parantezde karışıklık olmasın demiştin. Bence şu daha net:

```text
(D:T)       zaten T mi mutlak mı karışır
(D@T)       daha anlaşılır
(D@T+8)
```

Bu eklenirse FP macro’ları gerçekten saf UXM ile yazılabilir.

---

# 19. FP için gerekli yeni adresleme

UX-FP için olmazsa olmaz adresleme:

```text
(D@T)
(D@T+N)
(D@T-N)
```

Anlamı:

```text
T hücresindeki değer data base kabul edilir.
N kadar offset eklenir.
```

Örnek:

```text
# T hücresinde 100 var
.(D@T+8)
```

Bu:

```text
D:108
```

hücresini okur.

Bu olmadan her FP işlemini sadece sabit D adresleriyle yazmak gerekir, bu da kütüphaneyi kullanışsız yapar.

---

# 20. FP için gerekli yeni meta servisler

Eğer saf macro uzun gelirse host meta servisler eklenir.

Runtime tarafında `@200..@239` açılır.

Frame:

```text
T-2 = result base
T-1 = A base
T   = B base / parameter
T+1 = status
```

Örnek:

```text
>>
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
```

Runtime:

```text
@210:
    resultBase = T-2
    aBase      = T-1
    bBase      = T
    FP_ADD(resultBase, aBase, bBase)
    T+1 = status
```

---

# 21. FP print mantığı

FP_PRINT_DEC şu işi yapar:

```text
1. sign oku
2. mantissa limblerini en büyükten küçüğe oku
3. exponent’e göre nokta yerini bul
4. tam kısmı bas
5. nokta bas
6. fractional kısmı precision kadar bas
```

Örnek:

```text
mantissa = 1234567
exponent = -4
precision = 16
```

Yazdırma:

```text
123.4567000000000000
```

FP32:

```text
123.45670000000000000000000000000000
```

---

# 22. Önerdiğim gerçek geliştirme sırası

Bunu doğrudan projeye eklemek için sıralama şöyle olmalı:

```text
1. UXM V3.1 adresleme sistemine (D@T+N) ekle.
2. Runtime’a @200..@239 FP servislerini ekle.
3. FP blok okuma/yazma yardımcılarını FreeBASIC runtime’a yaz.
4. FP_INIT16, FP_INIT32, FP_FROM_INT, FP_PRINT_DEC ekle.
5. FP_ADD ve FP_SUB ekle.
6. FP_MUL ekle.
7. FP_DIV ekle.
8. FP_ROUND16 / FP_ROUND32 ekle.
9. VS Code extension docs içine UX-FP dokümanı koy.
10. Copilot instructions içine UX-FP kurallarını ekle.
```

---

# 23. İlk minimum çalışan FP hedefi

İlk çalışan sürümde sadece şunları yapalım:

```text
@200 FP_INIT16
@201 FP_INIT32
@220 FP_FROM_INT
@223 FP_PRINT_DEC
@210 FP_ADD
@212 FP_MUL
```

Bu yeterli olur.

Örnek program:

```text
# A = 12
# B = 34
# R = A + B

>>
0(T-2)+k100
@200

0(T-2)+k140
@200

0(T-2)+k180
@200

0(T-2)+k100
0(T-1)+k12
@220

0(T-2)+k140
0(T-1)+k34
@220

0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210

0(T-1)+k180
@223
```

Beklenen çıktı:

```text
46.0000000000000000
```

---

# 24. Son kararım

Mete abi, UX-MINIMA için en doğru floating point sistemi şu olmalı:

```text
Adı:
    UX-FP V1

Tip:
    Decimal floating point / big decimal

Temsil:
    sign + exponent + base-100 mantissa

Hassasiyet:
    FP16 = virgülden sonra 16 hane
    FP32 = virgülden sonra 32 hane

Bellek:
    Data alanında FP blokları

Macro alanı:
    m200..m239

Host hızlandırıcı:
    @200..@239

Zorunlu ek adresleme:
    (D@T)
    (D@T+N)
    (D@T-N)

Temel işlemler:
    INIT, CLEAR, COPY, NORMALIZE
    FROM_INT, FROM_DEC_STRING, PRINT_DEC
    ADD, SUB, MUL, DIV
    ROUND16, ROUND32
```

Bence ilk kodlama adımı şu olmalı:

```text
uxm31_runtime_fb_full.bas içine @200..@239 FP servislerini ekleyelim.
```

Çünkü 16/32 haneli decimal floating point’i saf UXM macro olarak yazmak mümkün ama çok uzun olur. Önce runtime hızlandırıcıyla doğru matematiği kurmak, sonra aynı mantığın saf UXM macro sürümünü parça parça yazmak daha sağlıklı olur.


Haklısın Mete abi. Bu adresleme **normal modda olmalı**:

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Bunlar wild mode işi değil. Wild sadece `@127` gibi **runtime memory layout değiştirme** işlerinde kalmalı.

Bir de önemli düzeltme: FP işlemlerini macro olarak kullanacaksak, macro içinden host meta servisi çağırmak için yeni bir zorunlu sözdizimi gerekiyor. Çünkü `m210={@210}` yazarsak compiler `@210` görünce yine `m210` macro’sunu açmaya çalışır ve sonsuz macro expansion olur. Bu yüzden şu kuralı ekliyoruz:

```text
@210     kullanıcı macro varsa macro çağırır, yoksa host meta çağırır
@!210    zorla host meta servisi çağırır
@#       aktif hücredeki değeri dinamik meta kabul eder
```

Aşağıdaki kodları V3.1 Full yapısına ekle.

---

# 1. Yeni adresleme sabitleri

`ADDR_...` sabitlerinin sonuna ekle:

```freebasic
Const ADDR_D_AT_T As Long=11
Const ADDR_D_AT_T_REL As Long=12
Const ADDR_D_AT_TBASE_REL As Long=13
```

`TInstr` içine ikinci adres değeri ekle:

```freebasic
Type TInstr
    op As Long
    amount As Long
    addrKind As Long
    addrVal As Long
    addrVal2 As Long
    text As String
    metaId As Long
    metaDyn As Long
    metaForceHost As Long
    brCond As Long
    brDir As Long
    brDist As Long
    brTarget As Long
    mate As Long
End Type
```

Bunun anlamı:

```text
addrVal  = base tape offset
addrVal2 = data offset
```

Örnek:

```text
(D@(T-2)+8)
```

şu olur:

```text
addrKind = ADDR_D_AT_TBASE_REL
addrVal  = -2
addrVal2 = 8
```

---

# 2. `AddInstr` fonksiyonunu genişlet

Eski:

```freebasic
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal txt As String)
```

Yeni:

```freebasic
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
```

Gövdedeki yeni hali:

```freebasic
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
    If InstrCount>=MAX_INSTR Then SyntaxError("instruction limiti doldu",1):Exit Sub
    InstrCount=InstrCount+1
    Instr(InstrCount).op=op
    Instr(InstrCount).amount=amount
    Instr(InstrCount).addrKind=addrKind
    Instr(InstrCount).addrVal=addrVal
    Instr(InstrCount).addrVal2=addrVal2
    Instr(InstrCount).text=txt
End Sub
```

Eski `AddInstr(...)` çağrılarında `addrVal2` için `0` geç:

```freebasic
AddInstr(OP_INC,amt,kind,val,0,Mid(code,startP,p-startP))
```

---

# 3. `ParseAddress` imzasını genişlet

Eski:

```freebasic
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long) As Long
```

Yeni:

```freebasic
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
Declare Function ParseSignedOffsetAfter(ByVal s As String, ByVal startPos As Long, ByRef outVal As Long) As Long
Declare Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
```

`ParseOneInstruction` içinde:

```freebasic
Dim val2 As Long
...
kind=ADDR_T
val=0
val2=0
...
hasAddr=ParseAddress(code,p,kind,val,val2)
```

ve bütün `AddInstr` çağrılarında:

```freebasic
AddInstr(OP_INC,amt,kind,val,val2,Mid(code,startP,p-startP))
```

---

# 4. Yeni `ParseAddress` ve `ParseAddressBody`

Bunu mevcut `ParseAddress` / `ParseAddressBody` yerine koy:

```freebasic
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
    Dim startP As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then Return 0
    If Mid(code,p,1)<>"(" Then Return 0
    startP=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceChar(c) Then
            SyntaxError("adresleme ifadesi icinde bosluk yasak",p)
            Return 0
        End If
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>")" Then SyntaxError("adresleme parantezi kapanmadi",startP):Return 0
    body=Mid(code,startP+1,p-startP-1)
    p=p+1
    If ParseAddressBody(body,kind,val,val2)=0 Then
        SyntaxError("gecersiz adresleme: ("+body+")",startP)
        Return 0
    End If
    Return 1
End Function
Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
    Dim b As String
    Dim pos As Long
    Dim inner As String
    Dim rest As String
    Dim rel As Long
    Dim off As Long
    b=UCase(TrimAll(body))
    val=0
    val2=0
    If b="T" Then kind=ADDR_T:Return 1
    If b="SP" Then kind=ADDR_SP:Return 1
    If b="P" Then kind=ADDR_P:Return 1
    If b="E" Then kind=ADDR_E:Return 1
    If b="F" Then kind=ADDR_F:Return 1
    If b="*T" Then kind=ADDR_IND_T:Return 1
    If Left(b,2)="T+" Then kind=ADDR_T_REL:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="T-" Then kind=ADDR_T_REL:val=-Val(Mid(b,3)):Return 1
    If Left(b,2)="T:" Then kind=ADDR_T_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="D:" Then kind=ADDR_D_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="S:" Then kind=ADDR_S_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,4)="*(T+" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,4)="*(T-" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=-Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,3)="D@T" Then
        kind=ADDR_D_AT_T_REL
        val=0
        If Len(b)>3 Then
            If Mid(b,4,1)="+" Then val2=Val(Mid(b,5)):Return 1
            If Mid(b,4,1)="-" Then val2=-Val(Mid(b,5)):Return 1
            Return 0
        End If
        val2=0
        Return 1
    End If
    If Left(b,4)="D@(" Then
        pos=InStr(4,b,")")
        If pos=0 Then Return 0
        inner=Mid(b,4,pos-4)
        rest=Mid(b,pos+1)
        If ParseTapeRelInside(inner,rel)=0 Then Return 0
        off=0
        If rest<>"" Then
            If Left(rest,1)="+" Then off=Val(Mid(rest,2))
            If Left(rest,1)="-" Then off=-Val(Mid(rest,2))
            If Left(rest,1)<>"+" And Left(rest,1)<>"-" Then Return 0
        End If
        kind=ADDR_D_AT_TBASE_REL
        val=rel
        val2=off
        Return 1
    End If
    Return 0
End Function
Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
    s=UCase(TrimAll(s))
    baseRel=0
    If s="T" Then baseRel=0:Return 1
    If Left(s,2)="T+" Then baseRel=Val(Mid(s,3)):Return 1
    If Left(s,2)="T-" Then baseRel=-Val(Mid(s,3)):Return 1
    Return 0
End Function
```

Artık şu yazımlar geçerli:

```text
0(D@T)+k70
0(D@T+8)+k12
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k16
0(D@(T-1)+8)+k34
.(D@(T)+8)
```

---

# 5. `@!N` host meta çağrısı

`ParseMeta` fonksiyonunu şu mantıkla değiştir:

```freebasic
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim forceHost As Long
    startP=p
    p=p+1
    forceHost=0
    If p>Len(code) Then SyntaxError("@ sonrasi meta id veya # bekleniyor",p):Exit Sub
    If Mid(code,p,1)="!" Then
        forceHost=1
        p=p+1
    End If
    If p>Len(code) Then SyntaxError("@! sonrasi host meta id bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMetaInstr(-1,1,0,"@#")
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>255 Then SyntaxError("meta id 0..255 araliginda olmali",startP):Exit Sub
    If forceHost=0 Then
        idx=FindMacroIndex(id)
        If idx<>0 Then
            ParseProgram(MacroDef(idx).txt,depth+1)
            Exit Sub
        End If
    End If
    AddMetaInstr(id,0,forceHost,Mid(code,startP,p-startP))
End Sub
```

`AddMetaInstr` imzası:

```freebasic
Declare Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
```

Gövde:

```freebasic
Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
    AddInstr(OP_META,0,ADDR_T,0,0,txt)
    Instr(InstrCount).metaId=metaId
    Instr(InstrCount).metaDyn=dynamicFlag
    Instr(InstrCount).metaForceHost=forceHost
End Sub
```

---

# 6. Native emitter içine dinamik data adresleme ekle

`EmitAddrPtr` içine şu case’leri ekle:

```freebasic
Case ADDR_D_AT_T_REL
    EmitAddrLoad(ADDR_T,0,"rax")
    If addrVal2>=0 Then
        If addrVal2<>0 Then EmitLine("    add rax, "+LTrim(Str(addrVal2)))
    Else
        EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
    End If
    If BoundsOn Then
        EmitLine("    cmp rax, DATA_CELLS")
        EmitLine("    jae __ux_err_data")
    End If
    Select Case CellBits
    Case 8
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
    Case 16
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
    Case 32
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
    End Select
Case ADDR_D_AT_TBASE_REL
    EmitAddrLoad(ADDR_T_REL,addrVal,"rax")
    If addrVal2>=0 Then
        If addrVal2<>0 Then EmitLine("    add rax, "+LTrim(Str(addrVal2)))
    Else
        EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
    End If
    If BoundsOn Then
        EmitLine("    cmp rax, DATA_CELLS")
        EmitLine("    jae __ux_err_data")
    End If
    Select Case CellBits
    Case 8
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
    Case 16
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
    Case 32
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
    End Select
```

Böylece native ASM tarafında:

```text
(D@(T-2)+8)
```

şuna dönüşür:

```text
rax = Tape[Ptr-2]
rax = rax + 8
r11 = ux_mem + DATA_OFFSET + rax * cellsize
```

---

# 7. Full tool interpreter içine aynı adreslemeyi ekle

`ResolveIndex` fonksiyonuna ekle:

```freebasic
Case ADDR_D_AT_T_REL
    spaceName="D"
    idx=Tape(Ptr)+av2
Case ADDR_D_AT_TBASE_REL
    spaceName="D"
    idx=Tape(Ptr+av)+av2
```

Bunun için `ResolveIndex` imzası da `av2` almalı:

```freebasic
Declare Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
```

Yeni gövde mantığı:

```freebasic
Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
    Dim idx As Long
    ok=1
    Select Case ak
    Case ADDR_T
        spaceName="T":idx=Ptr
    Case ADDR_T_REL
        spaceName="T":idx=Ptr+av
    Case ADDR_T_ABS
        spaceName="T":idx=av
    Case ADDR_D_ABS
        spaceName="D":idx=av
    Case ADDR_S_ABS
        spaceName="S":idx=av
    Case ADDR_SP
        spaceName="S":idx=SP-1
    Case ADDR_P
        spaceName="P":idx=0
    Case ADDR_E
        spaceName="E":idx=0
    Case ADDR_F
        spaceName="F":idx=0
    Case ADDR_IND_T
        spaceName="T":idx=Tape(Ptr)
    Case ADDR_IND_T_REL
        spaceName="T":idx=Tape(Ptr+av)
    Case ADDR_D_AT_T_REL
        spaceName="D":idx=Tape(Ptr)+av2
    Case ADDR_D_AT_TBASE_REL
        spaceName="D":idx=Tape(Ptr+av)+av2
    Case Else
        ok=0:idx=0
    End Select
    If BoundsOn Then
        If spaceName="T" And (idx<0 Or idx>=TapeCells) Then ok=0:SetStatus STATUS_PTR_BOUNDS
        If spaceName="D" And (idx<0 Or idx>=DataCells) Then ok=0:SetStatus STATUS_DATA_BOUNDS
        If spaceName="S" And (idx<0 Or idx>=StackCells) Then ok=0:SetStatus STATUS_STACK_UNDERFLOW
    End If
    Return idx
End Function
```

`ReadAddr` ve `WriteAddr` çağrılarını da şöyle değiştir:

```freebasic
idx=ResolveIndex(ak,av,av2,spn,ok)
```

---

# 8. UX-FP V1 macro kütüphanesi

Bunu ayrı dosya yap:

```text
ux_fp_v1.uxm
```

İlk sürümde temel işlemler macro arayüzü olarak tanımlanıyor. Basit header işlemleri saf UXM ile yapılır. Ağır işlemler `@!N` ile host hızlandırıcıya gider. Böylece programcı hep macro çağırır; istersek sonra `m210` içeriğini saf UXM ADD algoritmasına çevirebiliriz.

```text
# UX-FP V1 decimal floating point macro library
# Gerekli adresleme:
#   (D@T)
#   (D@T+N)
#   (D@(T-2)+N)
#   (D@(T-1)+N)
#   (D@(T)+N)
# Genel FP frame:
#   T-2 = result/destination base
#   T-1 = A/source base veya integer input
#   T   = B/source base veya parametre
#   T+1 = status/result

# m200 FP_INIT16
# T-2 = base
m200={
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k16
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+7)
0(D@(T-2)+8)
}

# m201 FP_INIT32
# T-2 = base
m201={
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k32
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+7)
0(D@(T-2)+8)
}

# m202 FP_ZERO / FP_CLEAR_VALUE
# T-2 = base
# Header korunur, sayı 0 yapılır.
m202={
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+8)
}

# m203 FP_COPY
# T-2 = destination base
# T-1 = source base
# T   = cell count, FP16 için 24, FP32 için 40
# Data block copy host servis ile yapılır.
m203={
@!98
}

# m204 FP_NORMALIZE
# T-2 = base
m204={
@!204
}

# m205 FP_SET_SIGN
# T-2 = base
# T-1 = sign, 0 pozitif, 1 negatif
m205={
0(D@(T-2)+2)
+(D@(T-2)+2)
}

# m206 FP_SET_EXP
# T-2 = base
# T-1 = exponent sign
# T   = exponent abs
m206={
0(D@(T-2)+3)
+(D@(T-2)+3)
0(D@(T-2)+4)
+(D@(T-2)+4)
}

# m207 FP_SET_LIMB_HOST
# T-2 = base
# T-1 = limb index
# T   = limb value
m207={
@!207
}

# m208 FP_GET_LIMB_HOST
# T-2 = base
# T-1 = limb index
# T+1 = limb value
m208={
@!208
}

# m209 FP_PRINT_RAW
# T-1 = base
m209={
@!209
}

# m210 FP_ADD
# T-2 = result base
# T-1 = A base
# T   = B base
m210={
@!210
}

# m211 FP_SUB
# T-2 = result base
# T-1 = A base
# T   = B base
m211={
@!211
}

# m212 FP_MUL
# T-2 = result base
# T-1 = A base
# T   = B base
m212={
@!212
}

# m213 FP_DIV
# T-2 = result base
# T-1 = A base
# T   = B base
m213={
@!213
}

# m214 FP_COMPARE
# T-1 = A base
# T   = B base
# T+1 = 0 equal, 1 A>B, maxcell A<B
m214={
@!214
}

# m215 FP_ABS
# T-2 = destination base
# T-1 = source base
m215={
@!215
}

# m216 FP_NEG
# T-2 = destination base
# T-1 = source base
m216={
@!216
}

# m217 FP_ROUND16
# T-2 = base
m217={
@!217
}

# m218 FP_ROUND32
# T-2 = base
m218={
@!218
}

# m219 FP_TRUNC
# T-2 = base
m219={
@!219
}

# m220 FP_FROM_INT
# T-2 = destination base
# T-1 = integer value
m220={
@!220
}

# m221 FP_FROM_DEC_STRING
# T-2 = destination base
# T-1 = data string start
m221={
@!221
}

# m222 FP_TO_DEC_STRING
# T-2 = source base
# T-1 = output data string start
m222={
@!222
}

# m223 FP_PRINT_DEC
# T-1 = source base
m223={
@!223
}

# m224 FP_SCALE10
# T-2 = base
# T-1 = signed decimal shift
m224={
@!224
}

# m225 FP_ALIGN_EXP
m225={
@!225
}

# m226 FP_SHIFT_LEFT_DEC
m226={
@!226
}

# m227 FP_SHIFT_RIGHT_DEC
m227={
@!227
}

# m230 FP_SQRT
m230={
@!230
}

# m231 FP_HYPOT
m231={
@!231
}

# m232 FP_SIN
m232={
@!232
}

# m233 FP_COS
m233={
@!233
}

# m234 FP_TAN
m234={
@!234
}
```

Burada temel işlemler programcı açısından macro’dur:

```text
@210 değil, @210 yazınca m210 varsa macro açılır.
m210 içinde @!210 ile host hızlandırıcı çağrılır.
```

Bu tasarımın avantajı şu:

```text
Kullanıcı FP_ADD işlemini macro olarak kullanır.
İstersek sonra m210 gövdesini tamamen saf UXM uzun toplama algoritmasına çeviririz.
Host hızlandırıcı değişse bile kullanıcı kodu değişmez.
```

---

# 9. Örnek FP programı

Bu örnek `ux_fp_v1.uxm` macro kütüphanesi kaynak dosyanın başına eklendi varsayımıyla çalışır.

```text
# FP example
# EXPECT_OUTPUT: 46.0000000000000000
# A = 12
# B = 34
# R = A + B

>>
0(T-2)+k100
@200

0(T-2)+k140
@200

0(T-2)+k180
@200

0(T-2)+k100
0(T-1)+k12
@220

0(T-2)+k140
0(T-1)+k34
@220

0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210

0(T-1)+k180
@223
```

Burada `@200`, `@220`, `@210`, `@223` aslında macro varsa macro çağırır. Macro içinde `@!200`, `@!220`, `@!210`, `@!223` host servislerine gider.

---

# 10. Runtime’a eklenecek FP meta yönlendirme

`ux_meta_call_ex` içine şu aralığı ekle:

```freebasic
ElseIf metaId>=200 And metaId<=239 Then
    MetaFloatingPoint metaId
```

Declare:

```freebasic
Declare Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Declare Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPZero(ByVal base As LongInt)
Declare Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Declare Sub FPPrintDecimal(ByVal base As LongInt)
Declare Function FPSignedExp(ByVal base As LongInt) As LongInt
Declare Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
Declare Function FPMantissaString(ByVal base As LongInt) As String
Declare Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Declare Function BigTrim(ByVal s As String) As String
Declare Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
Declare Function BigAdd(ByVal a As String, ByVal b As String) As String
Declare Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Declare Function BigMul(ByVal a As String, ByVal b As String) As String
```

İlk çalışan FP runtime çekirdeği:

```freebasic
Sub MetaFloatingPoint(ByVal metaId As ULongInt)
    Dim rBase As LongInt
    Dim aBase As LongInt
    Dim bBase As LongInt
    Dim aMant As String
    Dim bMant As String
    Dim rMant As String
    Dim expA As LongInt
    Dim expB As LongInt
    Dim expR As LongInt
    Dim signA As LongInt
    Dim signB As LongInt
    Dim signR As LongInt
    Dim cmp As LongInt
    rBase=CLngInt(Arg1())
    aBase=CLngInt(Arg2())
    bBase=CLngInt(Arg0())
    Select Case metaId
    Case 200
        FPInit rBase,16
        SetResult 0
    Case 201
        FPInit rBase,32
        SetResult 0
    Case 202
        FPZero rBase
        SetResult 0
    Case 204
        FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)
        SetResult 0
    Case 210
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        If expA>expB Then
            aMant=aMant+String(expA-expB,"0")
            expR=expB
        ElseIf expB>expA Then
            bMant=bMant+String(expB-expA,"0")
            expR=expA
        Else
            expR=expA
        End If
        If signA=signB Then
            rMant=BigAdd(aMant,bMant)
            signR=signA
        Else
            cmp=BigCmp(aMant,bMant)
            If cmp=0 Then
                rMant="0"
                signR=0
                expR=0
            ElseIf cmp>0 Then
                rMant=BigSubAbs(aMant,bMant)
                signR=signA
            Else
                rMant=BigSubAbs(bMant,aMant)
                signR=signB
            End If
        End If
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 212
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        rMant=BigMul(aMant,bMant)
        expR=expA+expB
        signR=signA Xor signB
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 220
        FPFromInt rBase,aBase
        SetResult 0
    Case 223
        FPPrintDecimal aBase
        SetResult 0
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
```

Dikkat: Burada `@220` frame’i şöyledir:

```text
T-2 = destination base
T-1 = integer value
```

Runtime tarafında `rBase=Arg1()` ve `aBase=Arg2()` olduğu için `FPFromInt rBase,aBase` doğrudur.

---

# 11. FP yardımcıları

Bunları runtime’a ekle:

```freebasic
Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
    If base<0 Or base+40>=CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    WriteData base+0,70
    WriteData base+1,prec
    WriteData base+2,0
    WriteData base+3,0
    WriteData base+4,0
    WriteData base+5,1
    WriteData base+6,0
    WriteData base+7,0
    WriteData base+8,0
    SetStatus STATUS_OK
End Sub
Sub FPZero(ByVal base As LongInt)
    WriteData base+2,0
    WriteData base+3,0
    WriteData base+4,0
    WriteData base+5,1
    WriteData base+6,0
    WriteData base+8,0
    SetStatus STATUS_OK
End Sub
Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
    Dim sign As LongInt
    Dim v As LongInt
    Dim mant As String
    sign=0
    v=value
    If v<0 Then sign=1:v=-v
    mant=LTrim(Str(v))
    FPStoreMantExp base,sign,mant,0
End Sub
Function FPSignedExp(ByVal base As LongInt) As LongInt
    Dim es As LongInt
    Dim ea As LongInt
    es=ReadData(base+3)
    ea=ReadData(base+4)
    If es<>0 Then Return -ea
    Return ea
End Function
Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
    If e<0 Then
        WriteData base+3,1
        WriteData base+4,Abs(e)
    Else
        WriteData base+3,0
        WriteData base+4,e
    End If
End Sub
Function FPMantissaString(ByVal base As LongInt) As String
    Dim used As LongInt
    Dim i As LongInt
    Dim limb As LongInt
    Dim s As String
    Dim part As String
    used=ReadData(base+5)
    If used<=0 Then Return "0"
    s=""
    For i=used-1 To 0 Step -1
        limb=ReadData(base+8+i)
        If i=used-1 Then
            s=s+LTrim(Str(limb))
        Else
            part=LTrim(Str(limb))
            If Len(part)=1 Then part="0"+part
            s=s+part
        End If
    Next
    Return BigTrim(s)
End Function
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
    Dim prec As LongInt
    Dim maxLimbs As LongInt
    Dim maxDigits As LongInt
    Dim used As LongInt
    Dim i As LongInt
    Dim part As String
    mant=BigTrim(mant)
    Do While Len(mant)>1 And Right(mant,1)="0"
        mant=Left(mant,Len(mant)-1)
        exp10=exp10+1
    Loop
    prec=ReadData(base+1)
    If prec<>16 And prec<>32 Then prec=16
    If prec=16 Then maxLimbs=16 Else maxLimbs=32
    maxDigits=maxLimbs*2
    If Len(mant)>maxDigits Then
        mant=Left(mant,maxDigits)
        WriteData base+6,6
    Else
        WriteData base+6,0
    End If
    For i=0 To maxLimbs-1
        WriteData base+8+i,0
    Next
    used=0
    Do While Len(mant)>0
        If Len(mant)>=2 Then
            part=Right(mant,2)
            mant=Left(mant,Len(mant)-2)
        Else
            part=mant
            mant=""
        End If
        WriteData base+8+used,Val(part)
        used=used+1
        If used>=maxLimbs Then Exit Do
    Loop
    If used=0 Then used=1
    WriteData base+0,70
    WriteData base+1,prec
    If mant="0" Then sign=0
    WriteData base+2,sign
    FPSetSignedExp base,exp10
    WriteData base+5,used
    SetStatus STATUS_OK
End Sub
Sub FPPrintDecimal(ByVal base As LongInt)
    Dim mant As String
    Dim exp10 As LongInt
    Dim sign As LongInt
    Dim prec As LongInt
    Dim pointPos As LongInt
    Dim intPart As String
    Dim fracPart As String
    mant=FPMantissaString(base)
    exp10=FPSignedExp(base)
    sign=ReadData(base+2)
    prec=ReadData(base+1)
    If prec<>16 And prec<>32 Then prec=16
    If sign<>0 And mant<>"0" Then Print "-";
    If exp10>=0 Then
        Print mant+String(exp10,"0");
        If prec>0 Then Print "."+String(prec,"0");
        Exit Sub
    End If
    pointPos=Len(mant)+exp10
    If pointPos>0 Then
        intPart=Left(mant,pointPos)
        fracPart=Mid(mant,pointPos+1)
    Else
        intPart="0"
        fracPart=String(Abs(pointPos),"0")+mant
    End If
    If Len(fracPart)<prec Then fracPart=fracPart+String(prec-Len(fracPart),"0")
    If Len(fracPart)>prec Then fracPart=Left(fracPart,prec)
    Print intPart+"."+fracPart;
End Sub
```

---

# 12. Big integer string yardımcıları

```freebasic
Function BigTrim(ByVal s As String) As String
    Do While Len(s)>1 And Left(s,1)="0"
        s=Mid(s,2)
    Loop
    If s="" Then s="0"
    Return s
End Function
Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
    a=BigTrim(a)
    b=BigTrim(b)
    If Len(a)>Len(b) Then Return 1
    If Len(a)<Len(b) Then Return -1
    If a>b Then Return 1
    If a<b Then Return -1
    Return 0
End Function
Function BigAdd(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim carry As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim sum As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    carry=0
    r=""
    Do While ia>0 Or ib>0 Or carry>0
        da=0:db=0
        If ia>0 Then da=Val(Mid(a,ia,1)):ia=ia-1
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        sum=da+db+carry
        r=Chr(48+(sum Mod 10))+r
        carry=sum\10
    Loop
    Return BigTrim(r)
End Function
Function BigSubAbs(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim borrow As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim d As LongInt
    Dim r As String
    If BigCmp(a,b)<0 Then Return "0"
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    borrow=0
    r=""
    Do While ia>0
        da=Val(Mid(a,ia,1))-borrow
        db=0
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        If da<db Then
            da=da+10
            borrow=1
        Else
            borrow=0
        End If
        d=da-db
        r=Chr(48+d)+r
        ia=ia-1
    Loop
    Return BigTrim(r)
End Function
Function BigMul(ByVal a As String, ByVal b As String) As String
    Dim la As LongInt
    Dim lb As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim ai As LongInt
    Dim bj As LongInt
    Dim p As LongInt
    Dim carry As LongInt
    Dim arr(0 To 255) As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    If a="0" Or b="0" Then Return "0"
    la=Len(a)
    lb=Len(b)
    For i=0 To 255
        arr(i)=0
    Next
    For i=la To 1 Step -1
        ai=Val(Mid(a,i,1))
        carry=0
        For j=lb To 1 Step -1
            bj=Val(Mid(b,j,1))
            p=(la-i)+(lb-j)
            arr(p)=arr(p)+ai*bj+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
        Next
        p=(la-i)+lb
        Do While carry>0
            arr(p)=arr(p)+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
            p=p+1
        Loop
    Next
    r=""
    For i=255 To 0 Step -1
        If r<>"" Or arr(i)<>0 Then r=r+Chr(48+arr(i))
    Next
    If r="" Then r="0"
    Return BigTrim(r)
End Function
```

---

# 13. Şimdilik çalışan FP kapsamı

Bu ilk FP koduyla gerçek çalışan temel şunlar olur:

```text
m200 / @!200   FP_INIT16
m201 / @!201   FP_INIT32
m202           FP_ZERO
m210 / @!210   FP_ADD
m212 / @!212   FP_MUL
m220 / @!220   FP_FROM_INT
m223 / @!223   FP_PRINT_DEC
```

Bölme için `m213 / @!213` servis yerini ayırdık. Onu ikinci aşamada `BigDiv` ile eklemek doğru olur; division en uzun ve test isteyen parça.

Net karar:

```text
(D@...) adresleme normal mod standardıdır.
@!N host meta zorla çağırma sözdizimi olmalıdır.
Temel floating point API macro olmalıdır.
Ağır hesap host hızlandırıcı ile başlar.
İleride aynı m210/m212/m213 gövdeleri saf UXM algoritmalara çevrilebilir.
```

Böylece UX-MINIMA programcısı hep şu tarzda çalışır:

```text
@200  FP_INIT16 macro
@220  FP_FROM_INT macro
@210  FP_ADD macro
@212  FP_MUL macro
@223  FP_PRINT_DEC macro
```

ama macro içinde gerçek motor şimdilik:

```text
@!200
@!220
@!210
@!212
@!223
```

ile host FP runtime’a gider.


Aşağıdaki parça, önceki FP başlangıcının devamıdır. Bunu **`uxm31_runtime_fb_full.bas`** içine ekleyeceğiz.

Bu aşamada `@200..@239` floating point servisleri gerçek çalışır hale geliyor.

---

# 1. Declare listesine eklenecekler

Runtime dosyasındaki declare bölümüne şunları ekle:

```freebasic id="8tw2xo"
Declare Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Declare Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPZero(ByVal base As LongInt)
Declare Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Declare Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Declare Sub FPFromDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Declare Sub FPToDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Declare Sub FPPrintDecimal(ByVal base As LongInt)
Declare Function FPFormatDecimal(ByVal base As LongInt) As String
Declare Function FPSignedExp(ByVal base As LongInt) As LongInt
Declare Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
Declare Function FPMantissaString(ByVal base As LongInt) As String
Declare Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Declare Sub FPRoundFrac(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPTrunc(ByVal base As LongInt)
Declare Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function BigTrim(ByVal s As String) As String
Declare Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
Declare Function BigAdd(ByVal a As String, ByVal b As String) As String
Declare Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Declare Function BigMul(ByVal a As String, ByVal b As String) As String
Declare Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
Declare Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
Declare Function DataString(ByVal startCell As LongInt) As String
Declare Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)
```

---

# 2. `ux_meta_call_ex` içine FP aralığını ekle

Mevcut `ux_meta_call_ex` içinde şu kontrol olmalı:

```freebasic id="2fd7sd"
Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr) Export
If metaId<20 Then
MetaCore metaId
ElseIf metaId<40 Then
MetaArithmetic metaId
ElseIf metaId<60 Then
MetaMath metaId
ElseIf metaId<80 Then
MetaIO metaId
ElseIf metaId<90 Then
MetaPointerMemory metaId
ElseIf metaId<128 Then
MetaFifoDataSortWild metaId
ElseIf metaId>=200 And metaId<=239 Then
MetaFloatingPoint metaId
Else
SetStatus STATUS_INVALID_META
End If
End Sub
```

---

# 3. Tam `MetaFloatingPoint` servisi

Bunu runtime dosyasına ekle:

```freebasic id="4ewy06"
Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Dim rBase As LongInt
Dim aBase As LongInt
Dim bBase As LongInt
Dim aMant As String
Dim bMant As String
Dim rMant As String
Dim expA As LongInt
Dim expB As LongInt
Dim expR As LongInt
Dim signA As LongInt
Dim signB As LongInt
Dim signR As LongInt
Dim cmp As LongInt
Dim scaleDigits As LongInt
Dim q As String
rBase=CLngInt(Arg1())
aBase=CLngInt(Arg2())
bBase=CLngInt(Arg0())
Select Case metaId
Case 200
FPInit rBase,16
SetResult 0
Case 201
FPInit rBase,32
SetResult 0
Case 202
FPZero rBase
SetResult 0
Case 203
FPCopy rBase,aBase
SetResult 0
Case 204
FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)
SetResult 0
Case 209
Print "FP RAW base=";aBase;" sign=";ReadData(aBase+2);" exp=";FPSignedExp(aBase);" mant=";FPMantissaString(aBase)
SetResult 0
Case 210
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
expR=expB
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
expR=expA
Else
expR=expA
End If
If signA=signB Then
rMant=BigAdd(aMant,bMant)
signR=signA
Else
cmp=BigCmp(aMant,bMant)
If cmp=0 Then
rMant="0"
signR=0
expR=0
ElseIf cmp>0 Then
rMant=BigSubAbs(aMant,bMant)
signR=signA
Else
rMant=BigSubAbs(bMant,aMant)
signR=signB
End If
End If
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 211
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2) Xor 1
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
expR=expB
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
expR=expA
Else
expR=expA
End If
If signA=signB Then
rMant=BigAdd(aMant,bMant)
signR=signA
Else
cmp=BigCmp(aMant,bMant)
If cmp=0 Then
rMant="0"
signR=0
expR=0
ElseIf cmp>0 Then
rMant=BigSubAbs(aMant,bMant)
signR=signA
Else
rMant=BigSubAbs(bMant,aMant)
signR=signB
End If
End If
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 212
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
rMant=BigMul(aMant,bMant)
expR=expA+expB
signR=signA Xor signB
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 213
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
If bMant="0" Then
WriteData rBase+6,4
SetStatus STATUS_DIV_ZERO
SetResult STATUS_DIV_ZERO
Exit Sub
End If
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If ReadData(rBase+1)=32 Then
scaleDigits=64
Else
scaleDigits=32
End If
q=BigDivInt(BigShift10(aMant,scaleDigits),bMant)
expR=expA-expB-scaleDigits
signR=signA Xor signB
FPStoreMantExp rBase,signR,q,expR
If ReadData(rBase+1)=32 Then FPRoundFrac rBase,32 Else FPRoundFrac rBase,16
SetResult 0
Case 214
cmp=FPCompare(aBase,bBase)
If cmp=0 Then
SetResult 0
ElseIf cmp>0 Then
SetResult 1
Else
SetResult CellMask()
End If
SetLogicFlags ResultValue()
Case 215
FPCopy rBase,aBase
WriteData rBase+2,0
SetResult 0
Case 216
FPCopy rBase,aBase
If FPMantissaString(rBase)<>"0" Then WriteData rBase+2,ReadData(rBase+2) Xor 1
SetResult 0
Case 217
FPRoundFrac rBase,16
SetResult 0
Case 218
FPRoundFrac rBase,32
SetResult 0
Case 219
FPTrunc rBase
SetResult 0
Case 220
FPFromInt rBase,aBase
SetResult 0
Case 221
FPFromDecString rBase,aBase
SetResult 0
Case 222
FPToDecString rBase,aBase
SetResult 0
Case 223
FPPrintDecimal aBase
SetResult 0
Case 224
FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)+aBase
SetResult 0
Case 230
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 231
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 232
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 233
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 234
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case Else
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
End Select
End Sub
```

Not: `@230..@234` için yer ayrıldı ama bu aşamada bilerek `STATUS_INVALID_META` dönüyor. Çünkü `SQRT/SIN/COS/TAN` için ya Newton metodu ya da tablo/seri yöntemi ayrıca yazılmalı.

---

# 4. FP blok yardımcıları

Bunları runtime dosyasına ekle:

```freebasic id="cvs48p"
Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Dim maxCells As LongInt
If prec=32 Then maxCells=40 Else maxCells=24
If base<0 Or base+maxCells>=CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
WriteData base+0,70
WriteData base+1,prec
WriteData base+2,0
WriteData base+3,0
WriteData base+4,0
WriteData base+5,1
WriteData base+6,0
WriteData base+7,0
WriteData base+8,0
SetStatus STATUS_OK
End Sub
Sub FPZero(ByVal base As LongInt)
WriteData base+2,0
WriteData base+3,0
WriteData base+4,0
WriteData base+5,1
WriteData base+6,0
WriteData base+8,0
SetStatus STATUS_OK
End Sub
Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Dim prec As LongInt
Dim maxCells As LongInt
Dim i As LongInt
prec=ReadData(srcBase+1)
If prec=32 Then maxCells=40 Else maxCells=24
If dstBase<0 Or srcBase<0 Or dstBase+maxCells>=CLngInt(ux_data_cells) Or srcBase+maxCells>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To maxCells-1
WriteData dstBase+i,ReadData(srcBase+i)
Next i
SetStatus STATUS_OK
End Sub
Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Dim sign As LongInt
Dim v As LongInt
Dim mant As String
sign=0
v=value
If v<0 Then sign=1:v=-v
mant=LTrim(Str(v))
FPStoreMantExp base,sign,mant,0
End Sub
Function FPSignedExp(ByVal base As LongInt) As LongInt
Dim es As LongInt
Dim ea As LongInt
es=ReadData(base+3)
ea=ReadData(base+4)
If es<>0 Then Return -ea
Return ea
End Function
Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
If e<0 Then
WriteData base+3,1
WriteData base+4,Abs(e)
Else
WriteData base+3,0
WriteData base+4,e
End If
End Sub
Function FPMantissaString(ByVal base As LongInt) As String
Dim used As LongInt
Dim i As LongInt
Dim limb As LongInt
Dim s As String
Dim part As String
used=ReadData(base+5)
If used<=0 Then Return "0"
s=""
For i=used-1 To 0 Step -1
limb=ReadData(base+8+i)
If i=used-1 Then
s=s+LTrim(Str(limb))
Else
part=LTrim(Str(limb))
If Len(part)=1 Then part="0"+part
s=s+part
End If
Next i
Return BigTrim(s)
End Function
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Dim prec As LongInt
Dim maxLimbs As LongInt
Dim maxDigits As LongInt
Dim used As LongInt
Dim i As LongInt
Dim part As String
mant=BigTrim(mant)
Do While Len(mant)>1 And Right(mant,1)="0"
mant=Left(mant,Len(mant)-1)
exp10=exp10+1
Loop
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
If prec=16 Then maxLimbs=16 Else maxLimbs=32
maxDigits=maxLimbs*2
If Len(mant)>maxDigits Then
mant=Left(mant,maxDigits)
WriteData base+6,6
Else
WriteData base+6,0
End If
For i=0 To maxLimbs-1
WriteData base+8+i,0
Next i
used=0
Do While Len(mant)>0
If Len(mant)>=2 Then
part=Right(mant,2)
mant=Left(mant,Len(mant)-2)
Else
part=mant
mant=""
End If
WriteData base+8+used,Val(part)
used=used+1
If used>=maxLimbs Then Exit Do
Loop
If used=0 Then used=1
WriteData base+0,70
WriteData base+1,prec
If BigTrim(FPMantissaString(base))="0" Then sign=0
WriteData base+2,sign
FPSetSignedExp base,exp10
WriteData base+5,used
SetStatus STATUS_OK
End Sub
```

Burada küçük bir not var: `FPStoreMantExp` içinde `FPMantissaString(base)` çağrısı henüz yeni yazılan mantissa’yı okuyacağı için sıfır kontrolünü daha temiz yapmak istersek şu satırı:

```freebasic id="qzlq87"
If BigTrim(FPMantissaString(base))="0" Then sign=0
```

şununla değiştirmek daha doğrudur:

```freebasic id="wogznd"
If BigTrim(mant)="0" Then sign=0
```

Ama `mant` döngüde boşaltıldığı için bunun için başta `origMant` tutmak gerekir. Daha sağlam sürüm aşağıdaki gibidir.

Yukarıdaki `FPStoreMantExp` yerine bunu kullan:

```freebasic id="g5nkme"
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Dim prec As LongInt
Dim maxLimbs As LongInt
Dim maxDigits As LongInt
Dim used As LongInt
Dim i As LongInt
Dim part As String
Dim origMant As String
mant=BigTrim(mant)
Do While Len(mant)>1 And Right(mant,1)="0"
mant=Left(mant,Len(mant)-1)
exp10=exp10+1
Loop
origMant=mant
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
If prec=16 Then maxLimbs=16 Else maxLimbs=32
maxDigits=maxLimbs*2
If Len(mant)>maxDigits Then
mant=Left(mant,maxDigits)
origMant=mant
WriteData base+6,6
Else
WriteData base+6,0
End If
For i=0 To maxLimbs-1
WriteData base+8+i,0
Next i
used=0
Do While Len(mant)>0
If Len(mant)>=2 Then
part=Right(mant,2)
mant=Left(mant,Len(mant)-2)
Else
part=mant
mant=""
End If
WriteData base+8+used,Val(part)
used=used+1
If used>=maxLimbs Then Exit Do
Loop
If used=0 Then used=1
WriteData base+0,70
WriteData base+1,prec
If BigTrim(origMant)="0" Then sign=0
WriteData base+2,sign
FPSetSignedExp base,exp10
WriteData base+5,used
SetStatus STATUS_OK
End Sub
```

---

# 5. Decimal string okuma/yazma

```freebasic id="k1ydp6"
Function DataString(ByVal startCell As LongInt) As String
Dim s As String
Dim i As LongInt
Dim v As ULongInt
s=""
i=startCell
Do While i>=0 And i<CLngInt(ux_data_cells)
v=ReadData(i)
If v=0 Then Exit Do
s=s+Chr(v And &HFF)
i=i+1
Loop
Return s
End Function
Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)
Dim i As LongInt
If startCell<0 Or startCell+Len(s)>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=1 To Len(s)
WriteData startCell+i-1,Asc(Mid(s,i,1)) And &HFF
Next i
WriteData startCell+Len(s),0
SetStatus STATUS_OK
End Sub
Sub FPFromDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Dim s As String
Dim i As LongInt
Dim c As String
Dim sign As LongInt
Dim mant As String
Dim fracCount As LongInt
Dim afterDot As Long
s=DataString(dataStart)
s=Trim(s)
sign=0
mant=""
fracCount=0
afterDot=0
If Left(s,1)="-" Then
sign=1
s=Mid(s,2)
ElseIf Left(s,1)="+" Then
s=Mid(s,2)
End If
For i=1 To Len(s)
c=Mid(s,i,1)
If c="." Or c="," Then
afterDot=1
ElseIf c>="0" And c<="9" Then
mant=mant+c
If afterDot<>0 Then fracCount=fracCount+1
End If
Next i
If mant="" Then mant="0"
FPStoreMantExp base,sign,mant,-fracCount
End Sub
Sub FPToDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
WriteDataString dataStart,FPFormatDecimal(base)
End Sub
Sub FPPrintDecimal(ByVal base As LongInt)
Print FPFormatDecimal(base);
End Sub
Function FPFormatDecimal(ByVal base As LongInt) As String
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim prec As LongInt
Dim pointPos As LongInt
Dim intPart As String
Dim fracPart As String
Dim out As String
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
out=""
If sign<>0 And mant<>"0" Then out="-"
If exp10>=0 Then
out=out+mant+String(exp10,"0")
If prec>0 Then out=out+"."+String(prec,"0")
Return out
End If
pointPos=Len(mant)+exp10
If pointPos>0 Then
intPart=Left(mant,pointPos)
fracPart=Mid(mant,pointPos+1)
Else
intPart="0"
fracPart=String(Abs(pointPos),"0")+mant
End If
If Len(fracPart)<prec Then fracPart=fracPart+String(prec-Len(fracPart),"0")
If Len(fracPart)>prec Then fracPart=Left(fracPart,prec)
out=out+intPart+"."+fracPart
Return out
End Function
```

---

# 6. Rounding ve truncation

```freebasic id="p5khxf"
Sub FPRoundFrac(ByVal base As LongInt, ByVal prec As LongInt)
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim drop As LongInt
Dim keepLen As LongInt
Dim kept As String
Dim nextDigit As LongInt
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
If exp10>=-prec Then
WriteData base+1,prec
Exit Sub
End If
drop=(-prec)-exp10
If drop<=0 Then
WriteData base+1,prec
Exit Sub
End If
If drop>=Len(mant) Then
mant="0"
exp10=-prec
FPStoreMantExp base,0,mant,exp10
WriteData base+1,prec
Exit Sub
End If
keepLen=Len(mant)-drop
kept=Left(mant,keepLen)
nextDigit=Val(Mid(mant,keepLen+1,1))
If nextDigit>=5 Then kept=BigAdd(kept,"1")
exp10=exp10+drop
FPStoreMantExp base,sign,kept,exp10
WriteData base+1,prec
SetStatus STATUS_OK
End Sub
Sub FPTrunc(ByVal base As LongInt)
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim drop As LongInt
Dim keepLen As LongInt
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
If exp10>=0 Then Exit Sub
drop=-exp10
If drop>=Len(mant) Then
FPStoreMantExp base,0,"0",0
Exit Sub
End If
keepLen=Len(mant)-drop
mant=Left(mant,keepLen)
FPStoreMantExp base,sign,mant,0
SetStatus STATUS_OK
End Sub
```

---

# 7. Compare fonksiyonları

```freebasic id="p2ddv7"
Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Dim aMant As String
Dim bMant As String
Dim expA As LongInt
Dim expB As LongInt
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
End If
Return BigCmp(aMant,bMant)
End Function
Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Dim signA As LongInt
Dim signB As LongInt
Dim cmp As LongInt
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If FPMantissaString(aBase)="0" And FPMantissaString(bBase)="0" Then Return 0
If signA=0 And signB<>0 Then Return 1
If signA<>0 And signB=0 Then Return -1
cmp=FPCompareAbs(aBase,bBase)
If signA<>0 Then cmp=-cmp
Return cmp
End Function
```

---

# 8. Big integer yardımcıları

```freebasic id="1rubj3"
Function BigTrim(ByVal s As String) As String
Do While Len(s)>1 And Left(s,1)="0"
s=Mid(s,2)
Loop
If s="" Then s="0"
Return s
End Function
Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
s=BigTrim(s)
If s="0" Then Return "0"
If n<=0 Then Return s
Return s+String(n,"0")
End Function
Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
a=BigTrim(a)
b=BigTrim(b)
If Len(a)>Len(b) Then Return 1
If Len(a)<Len(b) Then Return -1
If a>b Then Return 1
If a<b Then Return -1
Return 0
End Function
Function BigAdd(ByVal a As String, ByVal b As String) As String
Dim ia As LongInt
Dim ib As LongInt
Dim carry As LongInt
Dim da As LongInt
Dim db As LongInt
Dim sum As LongInt
Dim r As String
a=BigTrim(a)
b=BigTrim(b)
ia=Len(a)
ib=Len(b)
carry=0
r=""
Do While ia>0 Or ib>0 Or carry>0
da=0
db=0
If ia>0 Then da=Val(Mid(a,ia,1)):ia=ia-1
If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
sum=da+db+carry
r=Chr(48+(sum Mod 10))+r
carry=sum\10
Loop
Return BigTrim(r)
End Function
Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Dim ia As LongInt
Dim ib As LongInt
Dim borrow As LongInt
Dim da As LongInt
Dim db As LongInt
Dim d As LongInt
Dim r As String
If BigCmp(a,b)<0 Then Return "0"
a=BigTrim(a)
b=BigTrim(b)
ia=Len(a)
ib=Len(b)
borrow=0
r=""
Do While ia>0
da=Val(Mid(a,ia,1))-borrow
db=0
If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
If da<db Then
da=da+10
borrow=1
Else
borrow=0
End If
d=da-db
r=Chr(48+d)+r
ia=ia-1
Loop
Return BigTrim(r)
End Function
Function BigMul(ByVal a As String, ByVal b As String) As String
Dim la As LongInt
Dim lb As LongInt
Dim i As LongInt
Dim j As LongInt
Dim ai As LongInt
Dim bj As LongInt
Dim p As LongInt
Dim carry As LongInt
Dim arr(0 To 511) As LongInt
Dim r As String
a=BigTrim(a)
b=BigTrim(b)
If a="0" Or b="0" Then Return "0"
la=Len(a)
lb=Len(b)
For i=0 To 511
arr(i)=0
Next i
For i=la To 1 Step -1
ai=Val(Mid(a,i,1))
carry=0
For j=lb To 1 Step -1
bj=Val(Mid(b,j,1))
p=(la-i)+(lb-j)
arr(p)=arr(p)+ai*bj+carry
carry=arr(p)\10
arr(p)=arr(p) Mod 10
Next j
p=(la-i)+lb
Do While carry>0
arr(p)=arr(p)+carry
carry=arr(p)\10
arr(p)=arr(p) Mod 10
p=p+1
Loop
Next i
r=""
For i=511 To 0 Step -1
If r<>"" Or arr(i)<>0 Then r=r+Chr(48+arr(i))
Next i
If r="" Then r="0"
Return BigTrim(r)
End Function
Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
Dim i As LongInt
Dim digit As LongInt
Dim rems As String
Dim q As String
Dim c As String
numer=BigTrim(numer)
denom=BigTrim(denom)
If denom="0" Then Return "0"
If BigCmp(numer,denom)<0 Then Return "0"
rems="0"
q=""
For i=1 To Len(numer)
c=Mid(numer,i,1)
If rems="0" Then
rems=c
Else
rems=rems+c
End If
rems=BigTrim(rems)
digit=0
Do While BigCmp(rems,denom)>=0
rems=BigSubAbs(rems,denom)
digit=digit+1
Loop
q=q+Chr(48+digit)
Next i
Return BigTrim(q)
End Function
```

---

# 9. Macro kütüphanesinde güncelleme

`ux_fp_v1.uxm` içinde `m211`, `m213`, `m214`, `m217`, `m218`, `m219`, `m221`, `m222` artık gerçek host servislere gider:

```text id="g05n03"
m211={@!211}
m213={@!213}
m214={@!214}
m217={@!217}
m218={@!218}
m219={@!219}
m221={@!221}
m222={@!222}
```

Tam minimum FP macro başlığı şöyle olsun:

```text id="aj4pst"
# UX-FP V1 macro header
m200={@!200}
m201={@!201}
m202={@!202}
m203={@!203}
m204={@!204}
m209={@!209}
m210={@!210}
m211={@!211}
m212={@!212}
m213={@!213}
m214={@!214}
m215={@!215}
m216={@!216}
m217={@!217}
m218={@!218}
m219={@!219}
m220={@!220}
m221={@!221}
m222={@!222}
m223={@!223}
m224={@!224}
```

Bu şekilde kullanıcı açısından hepsi macro’dur. Macro içinde host çağrısı vardır.

---

# 10. Yeni FP testleri

## `tests_fp\test_fp01_add_int.uxm`

```text id="y2ux31"
# EXPECT_OUTPUT: 46.0000000000000000
# UX-FP V1 header burada include edilmiş varsayılır
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k12
@220
0(T-2)+k140
0(T-1)+k34
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
0(T-1)+k180
@223
```

## `tests_fp\test_fp02_sub_int.uxm`

```text id="s7pz6k"
# EXPECT_OUTPUT: 25.0000000000000000
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k100
@220
0(T-2)+k140
0(T-1)+k75
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@211
0(T-1)+k180
@223
```

## `tests_fp\test_fp03_mul_int.uxm`

```text id="0qap6p"
# EXPECT_OUTPUT: 408.0000000000000000
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k12
@220
0(T-2)+k140
0(T-1)+k34
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@212
0(T-1)+k180
@223
```

## `tests_fp\test_fp04_div_int.uxm`

```text id="jv1x92"
# EXPECT_OUTPUT: 3.3333333333333333
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k10
@220
0(T-2)+k140
0(T-1)+k3
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@213
0(T-1)+k180
@223
```

## `tests_fp\test_fp05_from_string.uxm`

```text id="49am5p"
# EXPECT_OUTPUT: 12.3400000000000000
s1=0,{12.34}
>>
0(T-2)+k100
@200
0(T-2)+k100
0(T-1)
@221
0(T-1)+k100
@223
```

## `tests_fp\test_fp06_add_dec_string.uxm`

```text id="7vlgld"
# EXPECT_OUTPUT: 17.9400000000000000
s1=0,{12.34}
s2=20,{5.6}
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)
@221
0(T-2)+k140
0(T-1)+k20
@221
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
0(T-1)+k180
@223
```

---

# 11. Şu anda FP kapsamı

Bu devamla beraber UX-FP V1’in temel hali şunları yapar:

```text id="4y7mze"
FP_INIT16
FP_INIT32
FP_ZERO
FP_COPY
FP_NORMALIZE
FP_ADD
FP_SUB
FP_MUL
FP_DIV
FP_COMPARE
FP_ABS
FP_NEG
FP_ROUND16
FP_ROUND32
FP_TRUNC
FP_FROM_INT
FP_FROM_DEC_STRING
FP_TO_DEC_STRING
FP_PRINT_DEC
FP_SCALE10
```

Kalan büyük bilimsel fonksiyonlar:

```text id="11806d"
FP_SQRT
FP_HYPOT
FP_SIN
FP_COS
FP_TAN
FP_LOG
FP_EXP
```

Bunları bir sonraki aşamada iki yoldan yazabiliriz:

```text id="2mu66y"
1. FP_SQRT: Newton-Raphson
2. SIN/COS/TAN: Taylor serisi veya önceden üretilmiş sinüs tablosu
```

Ama temel floating point sistemi artık oluştu: mantissa, exponent, sign, 16/32 hane, macro API ve host hızlandırıcı aynı tasarım altında bağlandı.


Evet Mete abi, **çekirdek tasarım büyük ölçüde tamamlandı**, ama “sağlam ürün” olması için hâlâ kalan işler var. Bunları önem sırasına göre yazıyorum.

## 1. En kritik kalan iş: Kodların tek projede birleştirilmesi

Şu anda parçalar halinde tasarladık:

```text
uxm31_compiler_fb_full.bas
uxm31_runtime_fb_full.bas
uxm31_full_tool_fb.bas
ux_fp_v1.uxm
uxminima-vscode/
```

Bunların artık tek proje ağacında düzenlenmesi gerekiyor:

```text
uxminima/
├─ compiler/
│  └─ uxm31_compiler_fb_full.bas
├─ runtime/
│  └─ uxm31_runtime_fb_full.bas
├─ tools/
│  └─ uxm31_full_tool_fb.bas
├─ lib/
│  └─ ux_fp_v1.uxm
├─ vscode-extension/
├─ tests/
├─ tests_full/
├─ tests_fp/
├─ docs/
└─ build/
```

Bu yapılmadan proje büyüdükçe karışır.

---

## 2. `(D@...)` adresleme modu mutlaka gerçek koda gömülmeli

Bu çok önemli. Çünkü FP macro sistemi buna dayanıyor.

Standart adresleme artık şunları desteklemeli:

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Bu adresleme **normal modda çalışmalı**. Wild mode’a bağlı olmamalı.

Bunu hem şu dosyalara gömmek gerekiyor:

```text
uxm31_compiler_fb_full.bas
uxm31_full_tool_fb.bas
VS Code diagnostics
VS Code syntax highlighting
UXM_LANGUAGE_SPEC.md
```

---

## 3. `@!N` host meta çağrısı kesinleştirilmeli

Floating point macro sisteminde bu şart oldu.

Kural:

```text
@210   macro varsa macro açılır
@!210  macro’ya bakmadan host runtime meta servisi çağrılır
@#     aktif hücredeki değeri meta id kabul eder
```

Bu kural olmadan `m210={@210}` sonsuz macro expansion’a girer. O yüzden `@!N` artık dil standardına eklenmeli.

---

## 4. FP sistemi için kalan bilimsel fonksiyonlar

Temel decimal floating point sistemi oluştu:

```text
FP_INIT16
FP_INIT32
FP_FROM_INT
FP_FROM_DEC_STRING
FP_PRINT_DEC
FP_ADD
FP_SUB
FP_MUL
FP_DIV
FP_COMPARE
FP_ABS
FP_NEG
FP_ROUND16
FP_ROUND32
FP_TRUNC
```

Ama bilimsel hesap için şunlar kaldı:

```text
FP_SQRT
FP_HYPOT
FP_SIN
FP_COS
FP_TAN
FP_LOG
FP_EXP
FP_POW
```

Bunları iki yoldan yapabiliriz:

```text
1. Runtime host meta servisleriyle hızlı hesap
2. UXM macro olarak eğitim/deney amaçlı yavaş hesap
```

İlk önce `FP_SQRT` ve `FP_HYPOT` yazmak mantıklı. Sonra sin/cos/tan için tablo veya Taylor serisi gelir.

---

## 5. Division testleri genişletilmeli

`FP_DIV` en riskli yer. Şu testler eklenmeli:

```text
1 / 3
10 / 3
100 / 7
-10 / 3
10 / -3
0 / 5
5 / 0
1.25 / 0.5
123456789 / 987
```

Çünkü decimal floating sistemde hata en çok bölmede çıkar.

---

## 6. FP rounding mantığı daha sert test edilmeli

Şunlar test edilmeli:

```text
1.23456789012345674  → FP16
1.23456789012345675  → FP16
9.99999999999999995  → FP16
0.00000000000000009  → FP16
```

Özellikle `999...` yuvarlanınca taşma olabiliyor:

```text
9.9999999999999999 → 10.0000000000000000
```

Bunu ayrıca kontrol etmek gerekir.

---

## 7. Native compiler ile full tool aynı standarda getirilmeli

Şu an üç ayrı katman var:

```text
native compiler
runtime
full tool interpreter
```

Bunların desteklediği dil özellikleri birebir aynı olmalı.

Özellikle şunlar eşitlenmeli:

```text
(D@...) adresleme
@!N host meta
FP macro çağrıları
UIR formatı
optimizer davranışı
branch davranışı
status/flags isimleri
```

Yoksa IDE’de çalışan kod native build’de farklı davranabilir.

---

## 8. VS Code eklentisi güncellenmeli

VS Code eklentisine şu yeni özellikler eklenmeli:

```text
(D@T+N) syntax highlighting
@!N renklendirme
FP macro hover açıklamaları
FP blok görüntüleme
Data alanında FP sayılarını decimal gösterme
ux_fp_v1.uxm snippetleri
Copilot instructions içine UX-FP kuralları
```

Memory watch paneli sadece hücre göstermemeli; FP bloklarını da tanımalı:

```text
D:100  FP16  12.3400000000000000
D:140  FP16   5.6000000000000000
D:180  FP16  17.9400000000000000
```

Bu çok güzel olur.

---

## 9. Test runner yazılmalı

Test dosyalarında şunu koymuştuk:

```text
# EXPECT_OUTPUT: AB
```

Artık bir test runner lazım.

Görevi:

```text
tests_full/*.uxm çalıştır
tests_fp/*.uxm çalıştır
EXPECT_OUTPUT satırını oku
gerçek çıktı ile karşılaştır
PASS / FAIL raporu üret
```

Rapor:

```text
test20_fifo_char_order.uxm   PASS
test_fp04_div_int.uxm        PASS
test_fp06_add_dec_string.uxm PASS
```

Bu olmazsa proje büyüdükçe neyin bozulduğunu göremeyiz.

---

## 10. Dokümantasyon güncellenmeli

Kullanma kılavuzuna şu yeni bölümler eklenmeli:

```text
(D@...) dinamik data adresleme
@!N host meta çağrısı
UX-FP V1 decimal floating point sistemi
FP blok yapısı
FP macro listesi
FP örnekleri
FP hata/status kodları
VS Code eklentisi kullanımı
Copilot ile UXM kod yazdırma kuralları
```

---

## 11. Build scriptleri birleştirilmeli

Şu komutları elle yazmak yerine:

```bat
fbc uxm31_compiler_fb_full.bas -x uxm31_compiler_full.exe
uxm31_compiler_full.exe program.uxm build\program.asm build\program.uir.json build\program.opt.json
nasm -f win64 build\program.asm -o build\program.obj
fbc uxm31_runtime_fb_full.bas build\program.obj -x build\program.exe
```

tek script olmalı:

```bat
build_native.bat program.uxm
run_trace.bat program.uxm
run_tests.bat
```

---

## 12. En son yapılacak ama önemli konu: Lisans ve GitHub düzeni

GitHub’a koyacaksak şunlar gerekir:

```text
README.md
LICENSE
CHANGELOG.md
CONTRIBUTING.md
docs/
examples/
tests/
```

Lisans için muhtemelen **MIT** uygun olur. Ama runtime/compiler senin projen olduğu için istersen daha kontrollü bir lisans da seçilebilir.

---

# Kısa cevap

Evet, kalan işler var ama artık “fikir” değil, **entegrasyon ve sağlamlaştırma işleri** kaldı.

En önemli 5 iş şunlar:

```text
1. (D@...) adreslemeyi compiler + interpreter + VS Code eklentisine gömmek.
2. @!N host meta çağrısını kesin standarda almak.
3. UX-FP V1 servislerini runtime’a tam bağlamak.
4. FP testlerini ve genel test runner’ı yazmak.
5. VS Code eklentisine FP ve memory watch desteğini eklemek.
```

Bence sıradaki en doğru adım:

```text
uxm31_compiler_fb_full.bas
uxm31_runtime_fb_full.bas
uxm31_full_tool_fb.bas
```

üçünü **tek standarda göre yeniden toparlamak**. Yani parçaları artık yamalı anlatmak yerine, “V3.1 Full Final” dosyaları olarak düzenlemek.


Mete abi, compiler’ı bu kez **tek merkezli ARGE compiler/tool** olarak yeniden düşündüm ve dosya halinde hazırladım:

[uxm31_final_project.zip](sandbox:/mnt/data/uxm31_final_project.zip)

İçinde ana dosya şu:

```text
uxm31_compiler_final.bas
```

Bu sürümün hedefi artık yalnızca `.uxm → asm` değil. Tek program içinde şu işler var:

```text
parse
diagnostics JSON
UIR JSON
optimizer raporu
interpreter modu
step / trace modu
IDE request-response JSON
native ASM emitter
ARGE komutları
(D@...) dinamik data adresleme
@!N host meta çağrısı
```

## Eklenen ARGE kaynak komutları

Kaynak dosya içine şunlar yazılabiliyor:

```text
#arge version
#arge json on
#arge interpreter on
#arge step on
#arge trace on
#arge optimize off
#arge watch tape=0:32
#arge watch data=100:40
#arge watch stack=0:16
```

Bunlar IDE için önemli. Mesela dosya içinde `#arge step on` varsa compiler/interpreter trace üretmeye hazır davranıyor.

## CLI kullanımı

```bat
fbc uxm31_compiler_final.bas -x uxm31_compiler_final.exe
```

Compile + JSON + trace:

```bat
uxm31_compiler_final.exe --input examples\final_probe.uxm --mode all --asm build\final_probe.asm --uir build\final_probe.uir.json --diag build\final_probe.diag.json --trace build\final_probe.trace.ndjson --opt build\final_probe.opt.json
```

Sadece interpreter:

```bat
uxm31_compiler_final.exe --input examples\final_probe.uxm --mode interpret --trace build\final_probe.trace.ndjson
```

Step modu:

```bat
uxm31_compiler_final.exe --input examples\final_probe.uxm --mode step --trace build\final_probe.trace.ndjson --max-steps 1000
```

IDE bağlantısı:

```bat
uxm31_compiler_final.exe --ide-in request.json --ide-out response.json
```

## IDE request örneği

```json
{"command":"step","source":"examples\\final_probe.uxm","trace":"build\\final_probe.trace.ndjson","uir":"build\\final_probe.uir.json","diag":"build\\final_probe.diag.json"}
```

Compiler response örneği:

```json
{"version":"UX-MINIMA x64 V3.1 FINAL-ARGE","status":0,"diagnostics":0,"instructions":42,"output":"AB"}
```

## Bu sürümde standarda alınan önemli dil ekleri

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
@!N
```

Yani FP macro sistemi için gerekli olan dinamik data adresleme artık normal mod standardı kabul ediliyor.

`@!N` de artık kesinleşti:

```text
@210   macro varsa macro açar
@!210  doğrudan host meta çağırır
@#     aktif hücredeki değeri meta id kabul eder
```

## Paket içeriği

```text
uxm31_final_project/
├─ uxm31_compiler_final.bas
├─ build_final.bat
├─ docs/
│  └─ UXM31_FINAL_ARGE_COMPILER.md
└─ examples/
   ├─ final_probe.uxm
   └─ dynamic_data_address.uxm
```

## Dürüst not

Bu ortamda FreeBASIC/NASM kurulu olmadığı için dosyayı burada gerçek `fbc` ile derleyemedim. Kod, önceki V3.1 tasarımımızı tek dosyada toparlayan **çalıştırılabilir hedefli FreeBASIC compiler/tool** olarak yazıldı; senin Windows ortamında ilk derlemede FreeBASIC’in yakalayacağı küçük syntax farkları çıkarsa onları doğrudan düzeltecek şekilde ilerleriz.

Bence sıradaki adım: bu paketi VS Code eklentisinin `tools/` klasörüne koyup `Run Step`, `Run Trace`, `Export UIR`, `Native Compile` komutlarını bu tek compiler’a bağlamak.


Tamam Mete abi, yaptım. Final ARGE compiler’ı VS Code eklentisine bağladım ve yeni paketi hazırladım:

[uxminima-vscode-final-arge.zip](sandbox:/mnt/data/uxminima-vscode-final-arge.zip)

İçine şunları ekledim:

```text
tools/uxm31_compiler_final.bas
tools/build_final_compiler.bat
docs/UXM31_FINAL_ARGE_COMPILER.md
docs/UXM_FINAL_IDE_USAGE.md
examples/final_probe.uxm
examples/dynamic_data_address.uxm
```

VS Code eklentisine yeni komutlar eklendi:

```text
UX-MINIMA: Build Final ARGE Compiler
UX-MINIMA: Final Compiler Run ALL
UX-MINIMA: Final Compiler Interpret Trace
UX-MINIMA: Final Compiler Step Mode
UX-MINIMA: Final Compiler Compile ASM
UX-MINIMA: Final Compiler Export UIR
UX-MINIMA: Final Compiler Export Diagnostics
UX-MINIMA: Final Compiler Export Optimizer Report
UX-MINIMA: Open Final ARGE Compiler Docs
```

Dil tarafına da şunları bağladım:

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
@!N
#arge ...
```

Ayrıca:

```text
@!N syntax highlighting eklendi
(D@...) syntax highlighting eklendi
@!N hover açıklaması eklendi
Final compiler trace formatı traceReader içine eklendi
Memory Watch final compiler step trace dosyasını okuyacak şekilde güncellendi
Copilot instructions dosyasına final compiler ve UX-FP kuralları eklendi
```

Kurulum:

```bat
cd uxminima-vscode
npm install
npm run compile
code .
```

Sonra VS Code içinde `F5`.

İlk test için:

```text
examples/final_probe.uxm
```

dosyasını açıp Command Palette’ten çalıştır:

```text
UX-MINIMA: Final Compiler Step Mode
```

Final compiler otomatik derlenmeye çalışır. Eğer otomatik olmazsa:

```text
UX-MINIMA: Build Final ARGE Compiler
```

komutunu çalıştır.

Dürüst not: Bu ortamda FreeBASIC/NASM çalıştıramadığım için `fbc` ile gerçek derleme testi yapamadım. Paket yapısı, TypeScript dosyaları ve entegrasyon mantığı hazır; Windows’ta ilk denemede FreeBASIC veya VS Code API kaynaklı küçük hata çıkarsa sıradaki adımda doğrudan düzeltiriz.


Evet Mete abi, **çok güzel bir test dosyası olur**. İlk aşamada tam opcode-fetch-decode yapan işlemci yerine, **4-bit CPU çekirdeği** gibi düşünelim:

```text
A register  = T:0
B register  = T:1
PC          = T:2
ALU_OUT     = T:3
CARRY4      = T:4
MASK4       = T:5
```

Bu testte 4-bit ALU şu işlemleri yapıyor:

```text
A = 12
B = 7

ADD : 12 + 7 = 19 → 4-bit sonuç 3, carry 1
AND : 12 AND 7 = 4
XOR : 12 XOR 7 = 11
SHL : 12 << 1 = 24 → 4-bit sonuç 8, carry 1
```

Aşağıdaki dosyayı şöyle kaydet:

```text
tests_full\test40_4bit_cpu_alu_model.uxm
```

```text
# TEST: Basit 4-bit CPU / ALU modeli
# MODEL:
#   T:0 = A register
#   T:1 = B register
#   T:2 = PC / frame pointer
#   T:3 = ALU_OUT
#   T:4 = CARRY4
#   T:5 = MASK4 = 15
# EXPECT_OUTPUT:
# 4BIT CPU TEST
# ADD=3 C=1
# AND=4
# XOR=11
# SHL=8 C=1

s1=0,{4BIT CPU TEST\n}
s2=32,{ADD=}
s3=40,{ C=}
s4=48,{\n}
s5=56,{AND=}
s6=64,{XOR=}
s7=72,{SHL=}

p1

# Register init:
# A = 12 = 1100b
# B = 7  = 0111b
0(T:0)+k12
0(T:1)+k7

# Pointer T:2 konumuna alınır.
# Böylece meta frame:
#   T-2 = A
#   T-1 = B
#   T+1 = ALU_OUT
>>

# ------------------------------------------------------------
# ADD instruction simulation
# A + B = 12 + 7 = 19
# 4-bit result = 19 AND 15 = 3
# carry = raw > 15
# ------------------------------------------------------------

p2
@20

# Raw result T:3 içindedir.
# Carry hesabı:
# stack = raw result
# T:4 = 15
# !(T:4) => stack_value > T:4 ise T:4 = 1
$(T:3)
0(T:4)+k15
!(T:4)

# 4-bit maskeleme:
# T:3 = T:3 AND 15
0(T:5)+k15
$(T:5)
&(T:3)

# ALU_OUT yazdır
@61

# Carry yazdır
p3
>
@61
<
p4

# ------------------------------------------------------------
# AND instruction simulation
# A AND B = 12 AND 7 = 4
# ------------------------------------------------------------

p5
$(T:1)
%(T:3)
$(T:0)
&(T:3)
@61
p4

# ------------------------------------------------------------
# XOR instruction simulation
# A XOR B = 12 XOR 7 = 11
# ------------------------------------------------------------

p6
$(T:1)
%(T:3)
$(T:0)
^(T:3)
@61
p4

# ------------------------------------------------------------
# SHL instruction simulation
# A << 1 = 24
# 4-bit result = 24 AND 15 = 8
# carry = raw > 15
# ------------------------------------------------------------

p7
$(T:0)
%(T:3)
{(T:3)

# carry hesabı
$(T:3)
0(T:4)+k15
!(T:4)

# 4-bit maskeleme
0(T:5)+k15
$(T:5)
&(T:3)

# sonuç yazdır
@61

# carry yazdır
p3
>
@61
<
p4
```

Beklenen çıktı:

```text
4BIT CPU TEST
ADD=3 C=1
AND=4
XOR=11
SHL=8 C=1
```

Bu test dosyası şunları aynı anda sınar:

```text
mutlak tape adresleme: (T:0), (T:1)
stack push/pop: $ ve %
bitwise AND/XOR
SHL: {
meta toplama: @20
decimal çıktı: @61
string çıktı: sN / pN
4-bit mask mantığı
carry hesaplama
```

Bu daha sonra gerçek 4-bit işlemci emülatörüne genişletilebilir. Bir sonraki aşamada ROM/Data alanına 4-bit opcode’lar koyup şu modeli kurarız:

```text
D:0..N = program ROM
T:0 = A
T:1 = B
T:2 = PC
T:3 = IR
T:4 = FLAGS
T:5 = ALU_OUT
```

Opcode örneği:

```text
0 = NOP
1 = LDA immediate
2 = LDB immediate
3 = ADD
4 = SUB
5 = AND
6 = OR
7 = XOR
8 = SHL
9 = SHR
10 = PRINT A
15 = HALT
```


Evet Mete abi. UX-MINIMA için **4 nöronlu küçük bir sinir ağı test dosyası** tasarlayabiliriz. Bu ilk sürüm eğitim yapan ağ değil; **ağırlıkları sabit, integer çalışan, ileri beslemeli mini sinir ağı** olacak.

Model:

```text
Girdi:
X1 = 1
X2 = 0
Nöronlar:
N1 = OR benzeri nöron      → step(X1 + X2 >= 1)
N2 = AND benzeri nöron     → step(X1 + X2 >= 2)
N3 = X1 algılayıcı nöron   → step(X1 >= 1)
N4 = çıktı nöronu          → step(N1 + N2 + N3 >= 2)
Beklenen:
N1 = 1
N2 = 0
N3 = 1
N4 = 1
```

Bunu şu test dosyası olarak kaydet:

```text
tests_full\test41_4_neuron_nn_model.uxm
```

```text
# TEST: 4 nöronlu basit sinir ağı modeli
# MODEL:
#   X1 = T:0
#   X2 = T:1
#   N1 = T:12  step(X1+X2 >= 1)
#   N2 = T:13  step(X1+X2 >= 2)
#   N3 = T:14  step(X1 >= 1)
#   N4 = T:15  step(N1+N2+N3 >= 2)
#   T:20,T:21,T:22,T:23 = meta işlem frame alanı
# EXPECT_OUTPUT:
# 4 NEURON NN TEST
# X1=1 X2=0
# N1=1 N2=0 N3=1 OUT=1
s1=0,{4 NEURON NN TEST\n}
s2=32,{X1=}
s3=40,{ X2=}
s4=48,{\n}
s5=56,{N1=}
s6=64,{ N2=}
s7=72,{ N3=}
s8=80,{ OUT=}
p1
# Girdiler
0(T:0)+k1
0(T:1)
# Pointer T:22 konumuna alınır.
# Böylece @20 toplama servisi için:
# T-2 = T:20
# T-1 = T:21
# T+1 = T:23 olur.
>>>>>>>>>>>>>>>>>>>>>>
# Girdileri yazdır
p2
$(T:0)
%(T:23)
@61
p3
$(T:1)
%(T:23)
@61
p4
# ------------------------------------------------------------
# N1 = step(X1 + X2 >= 1)
# Yani X1+X2 > 0 ise N1=1
# ------------------------------------------------------------
$(T:0)
%(T:20)
$(T:1)
%(T:21)
@20
0(T:11)
$(T:23)
!(T:11)
$(T:11)
%(T:12)
# ------------------------------------------------------------
# N2 = step(X1 + X2 >= 2)
# Yani X1+X2 > 1 ise N2=1
# ------------------------------------------------------------
$(T:0)
%(T:20)
$(T:1)
%(T:21)
@20
0(T:11)+k1
$(T:23)
!(T:11)
$(T:11)
%(T:13)
# ------------------------------------------------------------
# N3 = step(X1 >= 1)
# Yani X1 > 0 ise N3=1
# ------------------------------------------------------------
0(T:11)
$(T:0)
!(T:11)
$(T:11)
%(T:14)
# ------------------------------------------------------------
# N4 = step(N1 + N2 + N3 >= 2)
# Önce N1+N2 hesaplanır.
# Sonra sonuç + N3 hesaplanır.
# Sonra toplam > 1 ise OUT=1.
# ------------------------------------------------------------
$(T:12)
%(T:20)
$(T:13)
%(T:21)
@20
$(T:23)
%(T:20)
$(T:14)
%(T:21)
@20
0(T:11)+k1
$(T:23)
!(T:11)
$(T:11)
%(T:15)
# ------------------------------------------------------------
# Nöron çıktılarını yazdır
# ------------------------------------------------------------
p5
$(T:12)
%(T:23)
@61
p6
$(T:13)
%(T:23)
@61
p7
$(T:14)
%(T:23)
@61
p8
$(T:15)
%(T:23)
@61
p4
```

Beklenen çıktı:

```text
4 NEURON NN TEST
X1=1 X2=0
N1=1 N2=0 N3=1 OUT=1
```

Bu test, UX-MINIMA’da şunları aynı anda sınar:

```text
mutlak tape adresleme
stack ile hücre kopyalama
@20 toplama meta servisi
! büyüktür karşılaştırması
step aktivasyon fonksiyonu
4 nöronlu feed-forward mantık
decimal çıktı
string çıktı
trace ile nöron durumlarını izleme
```

Bunun bir üst seviyesi, aynı modeli **ağırlıklı sinir ağına** çevirmek olur:

```text
SUM = X1*W1 + X2*W2 + B
OUT = step(SUM >= threshold)
```

O zaman `@22` çarpma, `@20` toplama ve ileride yazdığımız UX-FP decimal floating point sistemi devreye girer.


Evet Mete abi, olur. Ama burada kritik karar şu:

**Kullanıcı denklemi doğrudan `f(x)=3*x^2+2*x+1` diye yazarsa compiler’ın expression parser yazması gerekir.** Bu yapılabilir ama ilk aşamada en sağlam yol bu değil.

UX-MINIMA mantığına uygun en doğru yol:

```text
1. Polinomlar katsayı tablosu olarak girilecek.
2. Türev ve integral macro olarak çağrılacak.
3. Macro içi şimdilik @! host servise gidecek.
4. İleride aynı macro gövdesi saf UXM algoritmaya çevrilebilir.
```

Yani kullanıcı için işlem yine macro olacak:

```text
@240  POLY_DERIV macro
@241  POLY_INTEGRAL macro
@242  POLY_EVAL macro
@243  POLY_PRINT macro
```

Ama macro içinde:

```text
m240={@!240}
m241={@!241}
m242={@!242}
m243={@!243}
```

olacak.

---

# 1. Denklem nasıl girilecek?

İlk sürümde denklem **polinom katsayı tablosu** olarak girilecek.

Örneğin:

```text
f(x) = 8x^3 + 6x^2 + 4x + 2
```

Bunu şöyle saklarız:

```text
coeff[0] = 2
coeff[1] = 4
coeff[2] = 6
coeff[3] = 8
```

Yani küçük dereceden büyüğe:

```text
2 + 4x + 6x^2 + 8x^3
```

Data bloğu:

```text
D:100+0 = 80      # magic: 'P' polynomial
D:100+1 = 1       # format version
D:100+2 = 3       # degree
D:100+3 = 0       # scale, şimdilik tam sayı
D:100+4 = 2       # x^0 katsayısı
D:100+5 = 4       # x^1 katsayısı
D:100+6 = 6       # x^2 katsayısı
D:100+7 = 8       # x^3 katsayısı
```

Bu polinomun türevi:

```text
f'(x) = 24x^2 + 12x + 4
```

Katsayı tablosu:

```text
4, 12, 24
```

İntegrali:

```text
∫f(x)dx = 2x^4 + 2x^3 + 2x^2 + 2x + C
```

Katsayı tablosu, C=0 olursa:

```text
0, 2, 2, 2, 2
```

---

# 2. Polinom blok formatı

Standart blok:

```text
D:BASE+0   magic = 80       # 'P'
D:BASE+1   version = 1
D:BASE+2   degree
D:BASE+3   scale
D:BASE+4   coeff[0]
D:BASE+5   coeff[1]
D:BASE+6   coeff[2]
...
```

`scale` ileride fixed-point için kullanılacak.

Örnek:

```text
scale = 0  → katsayılar tam sayı
scale = 2  → 123 değeri 1.23 anlamına gelir
scale = 6  → 1234567 değeri 1.234567 anlamına gelir
```

İlk testlerde `scale=0` kullanalım.

---

# 3. Macro kütüphanesi: `ux_poly_calc_v1.uxm`

Bunu ayrı dosya gibi düşün:

```text
# UX-POLY-CALC V1
# Polinom türev / integral / eval / print macro kütüphanesi
# Denklem data alanında katsayı tablosu olarak tutulur.
# Blok:
#   D:BASE+0 = 80
#   D:BASE+1 = version
#   D:BASE+2 = degree
#   D:BASE+3 = scale
#   D:BASE+4... = coefficients

# m240 POLY_DERIV
# T-2 = destination polynomial base
# T-1 = source polynomial base
m240={
@!240
}

# m241 POLY_INTEGRAL
# T-2 = destination polynomial base
# T-1 = source polynomial base
# T   = integration constant C
m241={
@!241
}

# m242 POLY_EVAL
# T-2 = source polynomial base
# T-1 = x value
# T+1 = result
m242={
@!242
}

# m243 POLY_PRINT
# T-1 = source polynomial base
m243={
@!243
}

# m244 POLY_CLEAR
# T-2 = polynomial base
# T-1 = max degree / cell count
m244={
@!244
}
```

Kullanıcı açısından bunlar macro’dur. Ama `@!240` sayesinde compiler macro expansion’a takılmadan host runtime servisine gider.

---

# 4. Türev macro kullanımı

Örnek:

```text
# f(x) = 8x^3 + 6x^2 + 4x + 2
# f'(x) = 24x^2 + 12x + 4

# Polinom P = D:100
# Türev   R = D:140

>>
0(T-2)+k140
0(T-1)+k100
@240

0(T-1)+k140
@243
```

Beklenen çıktı:

```text
4 + 12x + 24x^2
```

---

# 5. İntegral macro kullanımı

Örnek:

```text
# f(x) = 8x^3 + 6x^2 + 4x + 2
# integral = 2x^4 + 2x^3 + 2x^2 + 2x + C
# C = 0

>>
0(T-2)+k180
0(T-1)+k100
0(T)
@241

0(T-1)+k180
@243
```

Beklenen çıktı:

```text
0 + 2x + 2x^2 + 2x^3 + 2x^4
```

---

# 6. Test dosyası: `tests_math\test_poly01_derivative.uxm`

```text
# TEST: Polinom türev alma
# f(x)=8x^3+6x^2+4x+2
# EXPECT_OUTPUT: 4 + 12x + 24x^2

# ux_poly_calc_v1.uxm macro header burada var kabul edilir.

# P = D:100
# R = D:140

# P header
0(D:100)+k80
0(D:101)+k1
0(D:102)+k3
0(D:103)

# coefficients: 2 + 4x + 6x^2 + 8x^3
0(D:104)+k2
0(D:105)+k4
0(D:106)+k6
0(D:107)+k8

>>
0(T-2)+k140
0(T-1)+k100
@240

0(T-1)+k140
@243
```

---

# 7. Test dosyası: `tests_math\test_poly02_integral.uxm`

```text
# TEST: Polinom integral alma
# f(x)=8x^3+6x^2+4x+2
# EXPECT_OUTPUT: 0 + 2x + 2x^2 + 2x^3 + 2x^4

# P = D:100
# R = D:180

0(D:100)+k80
0(D:101)+k1
0(D:102)+k3
0(D:103)

0(D:104)+k2
0(D:105)+k4
0(D:106)+k6
0(D:107)+k8

>>
0(T-2)+k180
0(T-1)+k100
0(T)
@241

0(T-1)+k180
@243
```

---

# 8. Test dosyası: `tests_math\test_poly03_eval.uxm`

Bu testte:

```text
f(x)=8x^3+6x^2+4x+2
x=2
f(2)=8*8 + 6*4 + 4*2 + 2 = 64 + 24 + 8 + 2 = 98
```

```text
# TEST: Polinom değer hesaplama
# f(x)=8x^3+6x^2+4x+2
# x=2
# EXPECT_OUTPUT: 98

0(D:100)+k80
0(D:101)+k1
0(D:102)+k3
0(D:103)

0(D:104)+k2
0(D:105)+k4
0(D:106)+k6
0(D:107)+k8

>>
0(T-2)+k100
0(T-1)+k2
@242
@61
```

---

# 9. Runtime tarafında meta servisler

`ux_meta_call_ex` içine yeni aralık:

```freebasic
ElseIf metaId>=240 And metaId<=249 Then
    MetaPolynomial metaId
```

Declare:

```freebasic
Declare Sub MetaPolynomial(ByVal metaId As ULongInt)
Declare Sub PolyDerivative(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Declare Sub PolyIntegral(ByVal dstBase As LongInt, ByVal srcBase As LongInt, ByVal constantC As LongInt)
Declare Function PolyEval(ByVal srcBase As LongInt, ByVal x As LongInt) As LongInt
Declare Sub PolyPrint(ByVal srcBase As LongInt)
Declare Sub PolyClear(ByVal base As LongInt, ByVal count As LongInt)
Declare Function ReadPolyCoeff(ByVal base As LongInt, ByVal idx As LongInt) As LongInt
Declare Sub WritePolyCoeff(ByVal base As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
```

Kod:

```freebasic
Sub MetaPolynomial(ByVal metaId As ULongInt)
Dim dstBase As LongInt
Dim srcBase As LongInt
Dim param As LongInt
Dim r As LongInt
dstBase=CLngInt(Arg1())
srcBase=CLngInt(Arg2())
param=CLngInt(Arg0())
Select Case metaId
Case 240
    PolyDerivative dstBase,srcBase
    SetResult ux_status
Case 241
    PolyIntegral dstBase,srcBase,param
    SetResult ux_status
Case 242
    r=PolyEval(dstBase,srcBase)
    SetResult r
    SetLogicFlags ResultValue()
Case 243
    PolyPrint srcBase
    SetResult ux_status
Case 244
    PolyClear dstBase,srcBase
    SetResult ux_status
Case Else
    SetStatus STATUS_INVALID_META
    SetResult STATUS_INVALID_META
End Select
End Sub
Function ReadPolyCoeff(ByVal base As LongInt, ByVal idx As LongInt) As LongInt
Return CLngInt(ReadData(base+4+idx))
End Function
Sub WritePolyCoeff(ByVal base As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
WriteData base+4+idx,value
End Sub
Sub PolyDerivative(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Dim deg As LongInt
Dim scale As LongInt
Dim i As LongInt
Dim c As LongInt
If ReadData(srcBase)<>80 Then
    SetStatus STATUS_DATA_BOUNDS
    Exit Sub
End If
deg=ReadData(srcBase+2)
scale=ReadData(srcBase+3)
WriteData dstBase+0,80
WriteData dstBase+1,1
If deg<=0 Then
    WriteData dstBase+2,0
    WriteData dstBase+3,scale
    WriteData dstBase+4,0
    SetStatus STATUS_OK
    Exit Sub
End If
WriteData dstBase+2,deg-1
WriteData dstBase+3,scale
For i=1 To deg
    c=ReadPolyCoeff(srcBase,i)
    WritePolyCoeff dstBase,i-1,c*i
Next i
SetStatus STATUS_OK
End Sub
Sub PolyIntegral(ByVal dstBase As LongInt, ByVal srcBase As LongInt, ByVal constantC As LongInt)
Dim deg As LongInt
Dim scale As LongInt
Dim i As LongInt
Dim c As LongInt
Dim denom As LongInt
If ReadData(srcBase)<>80 Then
    SetStatus STATUS_DATA_BOUNDS
    Exit Sub
End If
deg=ReadData(srcBase+2)
scale=ReadData(srcBase+3)
WriteData dstBase+0,80
WriteData dstBase+1,1
WriteData dstBase+2,deg+1
WriteData dstBase+3,scale
WritePolyCoeff dstBase,0,constantC
For i=0 To deg
    c=ReadPolyCoeff(srcBase,i)
    denom=i+1
    WritePolyCoeff dstBase,i+1,c\denom
Next i
SetStatus STATUS_OK
End Sub
Function PolyEval(ByVal srcBase As LongInt, ByVal x As LongInt) As LongInt
Dim deg As LongInt
Dim i As LongInt
Dim acc As LongInt
If ReadData(srcBase)<>80 Then
    SetStatus STATUS_DATA_BOUNDS
    Return 0
End If
deg=ReadData(srcBase+2)
acc=0
For i=deg To 0 Step -1
    acc=acc*x+ReadPolyCoeff(srcBase,i)
Next i
SetStatus STATUS_OK
Return acc
End Function
Sub PolyPrint(ByVal srcBase As LongInt)
Dim deg As LongInt
Dim i As LongInt
Dim c As LongInt
Dim printed As Long
If ReadData(srcBase)<>80 Then
    SetStatus STATUS_DATA_BOUNDS
    Exit Sub
End If
deg=ReadData(srcBase+2)
printed=0
For i=0 To deg
    c=ReadPolyCoeff(srcBase,i)
    If i=0 Then
        Print LTrim(Str(c));
    Else
        Print " + ";LTrim(Str(c));"x";
        If i>1 Then Print "^";LTrim(Str(i));
    End If
Next i
SetStatus STATUS_OK
End Sub
Sub PolyClear(ByVal base As LongInt, ByVal count As LongInt)
Dim i As LongInt
For i=0 To count-1
    WriteData base+i,0
Next i
SetStatus STATUS_OK
End Sub
```

Bu sürümde integralde bölme `\` ile tam sayı bölme yapıyor. Bu yüzden bazı polinomlarda kesirli katsayılar kırpılır.

Örneğin:

```text
5x integral → 2x^2
```

olur; gerçek sonuç:

```text
2.5x^2
```

Bunu çözmek için iki yol var.

---

# 10. Kesirli integral için doğru yaklaşım

İntegral katsayıları kesirli çıkabilir. Bunu doğru yapmak için `scale` kullanacağız.

Örneğin `scale=2` ise:

```text
250 = 2.50
```

Ama integralde `5/2=2.5` gibi değerleri kaybetmemek için kaynak polinom katsayılarını ölçekli girmek gerekir.

Örnek:

```text
f(x)=5x
scale=2
coeff[1]=500
```

İntegral:

```text
500 / 2 = 250
```

Yani:

```text
2.50x^2
```

Bu yüzden integral alırken önerilen kullanım:

```text
scale=2, 4 veya 6
```

Bilimsel kullanımda:

```text
scale=6
```

daha iyi olur.

---

# 11. İkinci denklem giriş yöntemi: RPN bytecode

Polinom dışında kullanıcı şunu yazmak isteyecek:

```text
sin(x) + x^2
```

Bunu katsayı tablosu ile temsil edemeyiz. Bunun için ikinci format gerekir: **RPN expression bytecode**.

Örnek:

```text
sin(x) + x^2
```

RPN olarak:

```text
x sin x 2 pow +
```

Data bloğu:

```text
D:300+0 = 69      # magic 'E'
D:300+1 = 1       # expression version
D:300+2 = token count
D:300+3... tokens
```

Token önerisi:

```text
1   CONST
2   VAR_X
10  ADD
11  SUB
12  MUL
13  DIV
14  POW_INT
20  SIN
21  COS
22  TAN
30  END
```

Örnek:

```text
x^2 + 3x + 2
```

RPN:

```text
x 2 pow 3 x * + 2 +
```

Ama bunun türevini sembolik almak daha zordur. İlk aşamada RPN için:

```text
@250 NUM_DERIV
@251 NUM_INTEGRAL_TRAP
@252 NUM_INTEGRAL_SIMPSON
```

yapılır.

Yani:

```text
polinom → sembolik türev/integral
RPN ifade → sayısal türev/integral
```

Bu en doğru ayrım.

---

# 12. Genel karar

Bence UX-MINIMA’da türev/integral sistemi iki katmanlı olmalı:

```text
A) POLY-CALC
   Denklem katsayı tablosu olarak girilir.
   Türev ve integral sembolik yapılır.
   Macro servisleri:
      m240 POLY_DERIV
      m241 POLY_INTEGRAL
      m242 POLY_EVAL
      m243 POLY_PRINT

B) EXPR-CALC
   Denklem RPN bytecode olarak girilir.
   Türev ve integral sayısal yapılır.
   Macro servisleri:
      m250 EXPR_EVAL
      m251 NUM_DERIV
      m252 NUM_INTEGRAL_TRAP
      m253 NUM_INTEGRAL_SIMPSON
```

İlk uygulanacak sağlam sistem: **polinom türev/integral**.

Çünkü UX-MINIMA için en doğal denklem girişi budur:

```text
Denklem = data alanında katsayı tablosu
Türev   = katsayıları dereceyle çarpıp bir sola kaydırma
İntegral= katsayıları derece+1’e bölüp bir sağa kaydırma
```

Bu hem anlaşılır, hem test edilebilir, hem de VS Code IDE’de güzel gösterilir.


Var Mete abi. **Polinom türev/integral kısmı başlangıçtı.** Bunun devamında 4 ana bölüm daha var:

```text
1. RPN expression bytecode sistemi
2. Sayısal türev makrosu
3. Sayısal integral makroları
4. IDE’de denklem girme / görselleştirme sistemi
```

Bence sistem şöyle tamamlanmalı.

---

# 1. İki farklı matematik yolu olmalı

UX-MINIMA’da her denklemi aynı biçimde çözmeye çalışmak hata olur. İki yol ayırmak gerekir:

```text
A) POLY-CALC
   Polinomlar için.
   f(x)=8x^3+6x^2+4x+2 gibi denklemler.
   Katsayı tablosu ile girilir.
   Türev ve integral sembolik yapılır.

B) EXPR-CALC
   sin(x), cos(x), exp(x), log(x), x^2+sin(x) gibi ifadeler için.
   Denklem RPN bytecode olarak girilir.
   Türev ve integral sayısal yapılır.
```

Yani:

```text
Polinom ise:
    gerçek sembolik türev/integral

Genel denklem ise:
    sayısal türev/integral
```

Bu ayrım çok önemli.

---

# 2. RPN expression bytecode sistemi

Normal yazım:

```text
sin(x) + x^2
```

UX-MINIMA içinde doğrudan böyle parse etmek zor. Ama bunu RPN yani ters Lehçe gösterimle saklarsak kolaylaşır.

Normal ifade:

```text
sin(x) + x^2
```

RPN hali:

```text
x sin x 2 pow +
```

Bunu data alanında token listesi olarak tutarız.

---

# 3. Expression block formatı

Data alanında expression bloğu şöyle olsun:

```text
D:BASE+0   = 69      # magic: 'E'
D:BASE+1   = 1       # version
D:BASE+2   = token count
D:BASE+3   = scale / precision
D:BASE+4   = token 0
D:BASE+5   = token 1
D:BASE+6   = token 2
...
```

Token tablosu:

```text
1    CONST
2    VAR_X

10   ADD
11   SUB
12   MUL
13   DIV
14   POW_INT

20   SIN
21   COS
22   TAN
23   EXP
24   LOG
25   SQRT

30   NEG
31   ABS

99   END
```

Eğer token `CONST` ise hemen ardından sabit değer gelir.

Örnek:

```text
x^2 + 3x + 2
```

RPN:

```text
x 2 pow 3 x * + 2 +
```

Token dizisi:

```text
VAR_X
CONST 2
POW_INT
CONST 3
VAR_X
MUL
ADD
CONST 2
ADD
END
```

Data alanı:

```text
D:300 = 69
D:301 = 1
D:302 = 10
D:303 = 0

D:304 = 2      # VAR_X
D:305 = 1      # CONST
D:306 = 2
D:307 = 14     # POW_INT
D:308 = 1      # CONST
D:309 = 3
D:310 = 2      # VAR_X
D:311 = 12     # MUL
D:312 = 10     # ADD
D:313 = 1      # CONST
D:314 = 2
D:315 = 10     # ADD
D:316 = 99     # END
```

---

# 4. Expression eval macro

Macro alanı:

```text
m250 = EXPR_EVAL
```

Frame:

```text
T-2 = expression base
T-1 = x value
T+1 = result
```

Kullanım:

```text
>>
0(T-2)+k300
0(T-1)+k2
@250
@61
```

Bu, expression bloğunu `x=2` için hesaplar.

Eğer expression:

```text
x^2 + 3x + 2
```

ise sonuç:

```text
12
```

çünkü:

```text
2^2 + 3*2 + 2 = 12
```

---

# 5. Sayısal türev makrosu

Sayısal türev formülü:

```text
f'(x) ≈ (f(x+h) - f(x-h)) / (2h)
```

UX-MINIMA için macro:

```text
m251 = NUM_DERIV
```

Frame:

```text
T-2 = expression base
T-1 = x value
T   = h step
T+1 = result
```

Örnek:

```text
f(x)=x^2
x=5
h=1
```

Yaklaşık türev:

```text
(f(6)-f(4))/(2)
= (36-16)/2
= 10
```

Gerçek türev de:

```text
2x = 10
```

Macro kullanımı:

```text
>>
0(T-2)+k300
0(T-1)+k5
0(T)+k1
@251
@61
```

Beklenen çıktı:

```text
10
```

Bu ilk sürüm integer çalışır. UX-FP bağlanınca `h=0.001` gibi hassas değerler de kullanılabilir.

---

# 6. Sayısal integral: trapez yöntemi

Trapez integral formülü:

```text
∫a→b f(x) dx ≈ h * [ (f(a)+f(b))/2 + f(a+h)+f(a+2h)+...+f(b-h) ]
```

Macro:

```text
m252 = NUM_INTEGRAL_TRAP
```

Frame:

```text
T-2 = expression base
T-1 = a başlangıç
T   = b bitiş
T+1 = result
```

Ama burada `h` veya bölme sayısı da lazım. O yüzden frame yetersiz kalıyor. Daha doğru frame:

```text
T-4 = expression base
T-3 = a
T-2 = b
T-1 = n bölme sayısı
T+1 = result
```

Bu, mevcut 3 argüman frame yapısını biraz genişletir. Bu yüzden integral macro için standart frame şöyle olsun:

```text
T-4 = expr base
T-3 = a
T-2 = b
T-1 = n
T+1 = result
```

Bu durumda pointer integral çağrılarında biraz daha ileri alınmalı.

Örnek pointer `T:30` civarında tutulabilir.

```text
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
```

Sonra:

```text
0(T-4)+k300
0(T-3)
0(T-2)+k10
0(T-1)+k10
@252
@61
```

Bu:

```text
expr = D:300
a = 0
b = 10
n = 10
```

anlamına gelir.

---

# 7. Simpson integral makrosu

Daha doğru integral için Simpson yöntemi:

```text
∫a→b f(x) dx ≈ h/3 * [f(a)+f(b)+4f(a+h)+2f(a+2h)+4f(a+3h)+...]
```

Macro:

```text
m253 = NUM_INTEGRAL_SIMPSON
```

Frame:

```text
T-4 = expression base
T-3 = a
T-2 = b
T-1 = n
T+1 = result
```

Kural:

```text
n çift sayı olmalı
```

Eğer n tek sayıysa status hata vermeli:

```text
status = 31  # Simpson n must be even
```

---

# 8. Runtime meta servis tablosu

Yeni servisleri şöyle ayıralım:

```text
@240  POLY_DERIV
@241  POLY_INTEGRAL
@242  POLY_EVAL
@243  POLY_PRINT
@244  POLY_CLEAR

@250  EXPR_EVAL
@251  NUM_DERIV
@252  NUM_INTEGRAL_TRAP
@253  NUM_INTEGRAL_SIMPSON
@254  EXPR_PRINT_RPN
```

Macro header:

```text
m240={@!240}
m241={@!241}
m242={@!242}
m243={@!243}
m244={@!244}

m250={@!250}
m251={@!251}
m252={@!252}
m253={@!253}
m254={@!254}
```

Böylece kullanıcı açısından yine macro kullanımı var.

---

# 9. Denklem kullanıcıya nasıl girilecek?

Burada üç seviye olur.

## Seviye 1: Elle data tablosu

Kullanıcı doğrudan data alanına token yazar.

```text
D:300 = expression block
```

Bu zor ama sistemin çekirdeği için en sağlam yol.

## Seviye 2: IDE expression builder

VS Code eklentisinde kullanıcı şunu yazar:

```text
f(x)=x^2+3*x+2
```

IDE bunu RPN token listesine çevirir ve `.uxm` içine data bloğu olarak ekler.

Örneğin IDE otomatik üretir:

```text
#expr 300 = x^2 + 3*x + 2
```

Compiler bunu data bloğuna çevirir.

## Seviye 3: Compiler expression parser

Final compiler içine ARGE komutu ekleriz:

```text
#expr 300 = x^2 + 3*x + 2
#poly 100 = 2 + 4x + 6x^2 + 8x^3
```

Compiler parse eder ve data alanını kendisi üretir.

Bu en iyi nihai çözümdür.

---

# 10. Yeni ARGE komutları

Compiler’a şunlar eklenmeli:

```text
#poly BASE = c0,c1,c2,c3,...
#expr BASE = x^2 + 3*x + 2
#expr-rpn BASE = x 2 pow 3 x mul add 2 add
```

Örnek:

```text
#poly 100 = 2,4,6,8
```

şuna dönüşür:

```text
D:100 = 80
D:101 = 1
D:102 = 3
D:103 = 0
D:104 = 2
D:105 = 4
D:106 = 6
D:107 = 8
```

Örnek:

```text
#expr-rpn 300 = x 2 pow 3 x mul add 2 add
```

şuna dönüşür:

```text
D:300 = 69
D:301 = 1
D:302 = token_count
D:303 = scale
D:304... = tokens
```

Bu çok iyi olur. Çünkü kullanıcı artık ham data hücresi yazmak zorunda kalmaz.

---

# 11. IDE tarafında görünüm

VS Code eklentisinde özel panel:

```text
UX-MINIMA Math Blocks
├─ POLY D:100
│  ├─ f(x)=2 + 4x + 6x^2 + 8x^3
│  ├─ degree=3
│  └─ scale=0
├─ DERIV D:140
│  └─ f'(x)=4 + 12x + 24x^2
└─ EXPR D:300
   └─ x^2 + 3x + 2
```

Trace sırasında:

```text
@240 POLY_DERIV
D:140 = 4 + 12x + 24x^2
```

gibi gösterilir.

---

# 12. Bundan sonra kalan net işler

Devamı var, ama artık konu başlıkları netleşti:

```text
1. Compiler’a #poly parse komutu ekle.
2. Compiler’a #expr-rpn parse komutu ekle.
3. Runtime’a @250 EXPR_EVAL yaz.
4. Runtime’a @251 NUM_DERIV yaz.
5. Runtime’a @252 TRAPEZ integral yaz.
6. Runtime’a @253 SIMPSON integral yaz.
7. IDE’ye Math Blocks paneli ekle.
8. Copilot dokümanına #poly / #expr-rpn kurallarını ekle.
```

Benim kararım:

```text
Önce #poly + POLY_DERIV + POLY_INTEGRAL tamamlanmalı.
Sonra #expr-rpn + EXPR_EVAL.
En son NUM_DERIV ve NUM_INTEGRAL.
```

Çünkü polinom tarafı daha temiz, daha az hata çıkarır ve UX-MINIMA’nın data/tape yapısına daha doğal uyar.


Devam ettim Mete abi. Matematik uzantıları için ayrı bir ek paket hazırladım:

[uxm_math_extensions.zip](sandbox:/mnt/data/uxm_math_extensions.zip)

İçinde şunlar var:

```text
uxm_math_extensions/
├─ lib/
│  └─ ux_math_v1.uxm
├─ compiler/
│  └─ arge_parse_math_additions.bas
├─ runtime/
│  └─ runtime_math_services.bas
├─ tests_math/
│  ├─ test_math01_poly_deriv_arge.uxm
│  ├─ test_math02_poly_integral_arge.uxm
│  ├─ test_math03_poly_eval_arge.uxm
│  ├─ test_math04_expr_rpn_eval.uxm
│  ├─ test_math05_num_deriv.uxm
│  ├─ test_math06_integral_trap.uxm
│  └─ test_math07_integral_simpson.uxm
└─ docs/
   └─ UXM_MATH_EXTENSIONS.md
```

Bu paketteki yeni matematik katmanı şunları ekliyor:

```text
#poly BASE = c0,c1,c2,c3,...
#expr-rpn BASE = x 2 pow 3 x mul add 2 add
```

Macro/meta servisleri:

```text
m240 / @!240  POLY_DERIV
m241 / @!241  POLY_INTEGRAL
m242 / @!242  POLY_EVAL
m243 / @!243  POLY_PRINT
m244 / @!244  POLY_CLEAR

m250 / @!250  EXPR_EVAL
m251 / @!251  NUM_DERIV
m252 / @!252  NUM_INTEGRAL_TRAP
m253 / @!253  NUM_INTEGRAL_SIMPSON
m254 / @!254  EXPR_PRINT_RPN
```

Örnek test:

```text
# TEST: #expr-rpn ile expression eval
# expression: x^2 + 3*x + 2, x=2, result=12
# EXPECT_OUTPUT: 12
#expr-rpn 300 = x 2 pow 3 x mul add 2 add
>>
0(T-2)+k300
0(T-1)+k2
@250
@61
```

Bu paket şu an **ekleme paketi** şeklinde. Yani `uxm31_compiler_final.bas` içine `compiler/arge_parse_math_additions.bas` içeriği, `uxm31_runtime_fb_full.bas` içine de `runtime/runtime_math_services.bas` içeriği gömülecek.

Bir sonraki adımda bunu doğrudan **Final Compiler + Runtime içine entegre edilmiş tek proje sürümü** olarak toparlayabiliriz.
