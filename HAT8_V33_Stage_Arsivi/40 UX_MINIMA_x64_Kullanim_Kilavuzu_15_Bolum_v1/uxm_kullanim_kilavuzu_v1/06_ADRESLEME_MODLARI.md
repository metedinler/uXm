# Bölüm 6 — Adresleme Modları ve Küçük Komutların Davranışı

UXM’nin asıl gücü küçük komutları farklı hedeflere uygulayabilmesidir. Normalde `+` aktif tape hücresini artırır. Fakat adresleme modu eklersen aynı komut başka hücreyi veya başka bellek alanını etkiler.

## Temel adresleme düşüncesi

```uxm
+        ; aktif tape hücresini artır
+(T)     ; aynı şey: aktif tape hücresi
+(T+1)   ; pointer'ın bir sağındaki tape hücresi
+(T-1)   ; pointer'ın bir solundaki tape hücresi
+(T:100) ; tape[100]
+(D:5)   ; data[5]
+(S:0)   ; private stack[0]
```

Adresleme komuttan hemen sonra ve boşluksuz yazılır. `+(D:5)` doğru, `+ (D:5)` yanlış kabul edilmelidir. Çünkü UXM parser’ı komut ile adresleme bloğunu tek bir yapı olarak görür.

## Komut ve adresleme tablosu

| Komut | Adressiz davranış | Adresli örnek | Anlam |
|---|---|---|---|
| `+` | aktif hücreyi artırır | `+(D:10)` | data[10] artır |
| `-` | aktif hücreyi azaltır | `-(T+1)` | sağdaki tape hücresini azalt |
| `.` | aktif hücreyi yazdırır | `.(D:5)` | data[5] yazdır |
| `,` | input alır | `,(D:0)` | input’u data[0] alanına al |
| `>` | pointer sağa | genelde adres almaz | tape pointer ilerlet |
| `<` | pointer sola | genelde adres almaz | tape pointer geri al |
| `[` | aktif hücre sıfır değilken döngü | `[ ... ]` | loop başlangıcı |
| `]` | döngü sonu | `[ ... ]` | loop bitişi |
| `@N` | meta servis çağırır | `@20` | toplama servisi |
| `@(ADDR)` | dinamik meta servis | `@(D:0)` | servis id’sini data[0] gibi yerden al |

## Hücreye sayı ekleme ve çıkarma

```uxm
+++++      ; aktif hücre = 5
---        ; aktif hücre = 2
+(T+1)     ; sağdaki hücreyi 1 artır
-(D:10)    ; data[10] değerini 1 azalt
```

Daha büyük sayılar için servis veya tekrar makroları kullanılabilir. Örneğin 65 yazdırmak için byte karakter mantığında 65 kez `+` yazmak mümkündür ama pratik değildir. Daha gelişmiş programlar data alanını ve servisleri kullanır.

## Pointer ileri geri

```uxm
>      ; pointer bir hücre sağa
<      ; pointer bir hücre sola
>>>>>  ; beş hücre sağa
```

Pointer hareketi tape alanı içindir. Data alanı ise genellikle doğrudan adreslenir: `(D:0)`, `(D:1)`, `(D:100)`.

## Döngü mantığı

```uxm
+++++[.-]
```

Bu örnek aktif hücreyi 5 yapar. Döngü içinde değeri yazdırır ve azaltır. Değer sıfır olunca döngü biter. Döngüler UXM’de algoritma kurmanın temel yoludur.

## Meta servis çağırma

```uxm
@20     ; ADD servisi
@21     ; SUB servisi
@60     ; PRINT ARG2 DECIMAL gibi I/O servisi
```

Servisler genellikle tape üzerinde belirli konumlardan argüman bekler. Registry’de sık görülen ABI ifadesi `T-2=Arg1, T-1=Arg2, T=Arg0, T+1=result` biçimindedir. Bu şu demektir: pointer’ın çevresindeki hücrelere argümanları koy, servisi çağır, sonucu `T+1` hücresinden oku veya yazdır.
