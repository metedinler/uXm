# Bölüm 15 — Örneklerle Öğrenme Yolu ve Büyük Program Kurma Mantığı

UXM öğrenmenin doğru yolu küçük programlardan başlayıp servisleri birleştirmektir. Önce tape üzerinde sayı artırmayı öğren. Sonra data alanına geç. Sonra stack ve FIFO kullan. Daha sonra servis çağır. En sonunda bilimsel veya muhasebe benzeri küçük görevler kur.

## Örnek 1: aktif hücreyi artır ve yazdır

```uxm
#cell byte
+++++.
```

Bu program aktif hücreyi 5 yapar ve yazdırır. Byte hücre kullandığı için küçük sayılarla çalışır.

## Örnek 2: dword ile büyük sayı düşünmek

```uxm
#cell dword
#memory tape=1mb,data=4mb
```

Bu ayar, büyük sayılar ve bilimsel hesaplar için daha güvenlidir. Dword seçmek, byte kırpılmalarını önler.

## Örnek 3: data alanını tablo gibi düşünmek

```text
DATA[0] = öğrenci notu 1
DATA[1] = öğrenci notu 2
DATA[2] = öğrenci notu 3
```

Daha sonra istatistik servisiyle ortalama alınabilir. UXM’de gerçek kod servis ABI’ye göre yazılır; pseudo-code mantığı şöyledir:

```text
T-2 = data başlangıcı
T-1 = eleman sayısı
@MEAN
sonuç = T+1
```

## Örnek 4: muhasebe KDV hesabı

Bir ürünün fiyatı 100, KDV oranı 20 ise sonuç 120’dir. UXM’de bu iş için data alanına fiyat ve oran yazılır; çarpma/bölme/toplama servisleriyle sonuç elde edilir. Büyük programda bu adımlar fonksiyon gibi küçük bloklara ayrılır.

```text
fiyat = 100
kdv = fiyat * 20 / 100
toplam = fiyat + kdv
```

UXM düşüncesi:

```text
DATA[0]=100
DATA[1]=20
@MUL
@DIV
@ADD
PRINT sonuç
```

## Örnek 5: fen/kimya mol kütlesi

CH4O için C=12, H=1, O=16 alınırsa:

```text
12 + 4*1 + 16 = 32
```

Bu tür hesaplar UXM’de data alanına sabitler konarak ve arithmetic servisleriyle yapılabilir. Programcı her ara sonucu nereye koyduğunu bilmelidir.

## Örnek 6: biyoloji ölçüm serisi

Bir Chlorella deneyinde 5 OD ölçümü alındığını düşün:

```text
0.21, 0.24, 0.29, 0.31, 0.35
```

UXM’de floating point servisleri string veya scaled integer biçimiyle kullanılabilir. Başlangıçta scaled integer önerilir:

```text
21, 24, 29, 31, 35   ; 100 ile çarpılmış değerler
```

Sonra ortalama servisi veya manuel toplam/bölme kullanılır.

## Örnek 7: matrix ile küçük sistem

2x2 matrix:

```text
[1 2]
[3 4]
```

Data düz dizisi:

```text
1, 2, 3, 4
```

Index hesabı:

```text
index = row * 2 + col
```

Matrix servisleri bu düzen üzerinden çalışır. Determinant, inverse, rank gibi gelişmiş işlemler runtime servislerine bırakılır.

## Büyük program yazarken düşünme sırası

1. Verilerin hangi alanda duracağını seç: tape mi data mı?
2. Hücre tipini seç: byte mı dword mü?
3. Bellek boyutunu ayarla.
4. Girdi verisini data alanına yerleştir.
5. Servislerin beklediği argüman hücrelerini hazırla.
6. Servisi çağır.
7. Sonucu oku/yazdır/kaydet.
8. Test için `.expect` dosyası yaz.
9. `tum_test`, `hizli_tara`, `hatali_test` döngüsüyle doğrula.

## Profesyonel kaliteye geçiş

Başlangıçta her şeyi tek UXM dosyasında yazabilirsin. Daha sonra veri hazırlama, servis çağırma ve raporlama kısımlarını ayrı bloklar olarak düşün. Kullandığın her servis için küçük test yaz. Büyük programı küçük testlerin toplamı haline getir. Compiler geliştirme projelerinde güvenilirlik böyle sağlanır.
