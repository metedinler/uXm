# Bölüm 9 — Liste, Sözlük, Küme, Matrix ve Tensor Mantığı

UXM’de Python’daki gibi doğrudan `list`, `dict`, `set` keywordleriyle başlayan yüksek seviyeli veri yapıları yerine, veri yapıları çoğunlukla data alanında düzenlenen bloklar ve servis çağrılarıyla kurulur. Liste ardışık data hücreleri olarak düşünülebilir. Sözlük anahtar-değer çiftlerinin iki paralel blokta veya kayıt yapısında tutulmasıdır. Küme, tekrar etmeyen değerler listesi gibi uygulanabilir. Matrix iki boyutlu, tensor ise çok boyutlu data bloklarının düzenlenmiş halidir.

## Liste mantığı

```text
DATA[base + 0] = eleman 0
DATA[base + 1] = eleman 1
DATA[base + 2] = eleman 2
```

Liste üzerinde toplama, arama, sıralama gibi işler servislerle yapılır. Küçük örneklerde pointer ile tek tek gezmek de mümkündür.

## Sözlük mantığı

```text
KEYS[baseK + i]   = anahtar
VALUES[baseV + i] = değer
```

Bir anahtar arandığında önce key listesinde aranır, bulunan indeks value listesinde kullanılır. UXM’de bu doğrudan keyword değil, programlama tekniği olarak öğretilmelidir.

## Matrix mantığı

Matrix iki boyutlu dizidir. 2x3 matrix, data alanında düz blok olarak tutulabilir:

```text
index = row * column_count + col
DATA[base + index]
```

Örnek 2x2 matrix:

```text
[1 2]
[3 4]
```

Düz data:

```text
DATA[base+0]=1
DATA[base+1]=2
DATA[base+2]=3
DATA[base+3]=4
```

## Tensor mantığı

Tensor çok boyutlu dizidir. 3D için:

```text
index = z*(Y*X) + y*X + x
```

4D için:

```text
index = w*(Z*Y*X) + z*(Y*X) + y*X + x
```

UXM’de Stage-18 tensor4d köprüsünde yapılan düzeltmenin özü de budur: servis çağrısından önce dims ve index bilgisi data alanına doğru yazılmalıdır. Servis veri bulamazsa sıfır döndürmesi normaldir.

## Öğrenci için pratik öneri

Önce 1D listeyi data alanında kur. Sonra 2D matrix indeks formülünü öğren. Ardından 3D/4D tensor için aynı formülü genişlet. UXM’de büyük veri yapısı düşünmek, “verinin düz bellekte nereye düştüğünü” anlamaktır.
