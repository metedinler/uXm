# Bölüm 5 — Tape, Data, Stack, FIFO ve 16 MB Bellek Modeli

UXM’de bellek tek bir “değişkenler listesi” değildir. Dört temel alan vardır: **tape**, **data**, **private stack** ve **FIFO**. Bunlar birbirine benzer görünür ama düşünme biçimleri farklıdır. Tape aktif pointer ile yürüdüğün çalışma alanıdır. Data daha çok kalıcı tablo/dizi/string alanıdır. Stack son giren ilk çıkar mantığıyla geçici değer saklar. FIFO ise ilk giren ilk çıkar mantığıyla kuyruk oluşturur.

## Bellek alanları

| Alan | Mantık | Ne için kullanılır? |
|---|---|---|
| Tape | Pointer’ın üzerinde gezdiği hücre dizisi | küçük hesaplar, aktif değer, geçici işlem |
| Data | Adresle doğrudan erişilen veri alanı | string, tablo, matrix/tensor veri blokları |
| Stack | LIFO: son giren ilk çıkar | geçici argüman, ara sonuç, çağrı mantığı |
| FIFO | FIFO: ilk giren ilk çıkar | karakter akışı, kuyruk, buffer |

## Memory direktifi

```uxm
#memory total=16mb,tape=1mb,stack=256kb,data=4mb,fifo=1mb
```

Birimsiz değerler eski uyumluluk için KB kabul edilir:

```uxm
#memory data=4096
```

Bu ifade `data=4096kb`, yani yaklaşık 4 MB anlamına gelir. Byte, KB ve MB biçimleri kullanılabilir:

```uxm
#memory tape=2048b
#memory stack=512kb
#memory data=8mb
```

## Hücre tipi

Hücre tipi her hücrenin kaç bitlik değer taşıyacağını belirler. Byte küçük ve hızlıdır ama büyük sayıları tutamaz. Word orta boydur. Dword büyük sayılar ve bilimsel servis çıktıları için daha uygundur.

| Hücre tipi | Yaklaşık aralık | Kullanım |
|---|---|---|
| `byte` | 0..255 | karakter, küçük sayaç, ham byte |
| `word` | 0..65535 | orta büyüklükte sayaç |
| `dword` | 32-bit | büyük sayı, matrix/tensor indeksleri, servis sonuçları |

Örnek:

```uxm
#cell dword
#memory data=4mb
```

Bu ayar, data alanında 4 MB büyüklüğünde dword tabanlı çalışma yapmayı sağlar. Programcı, kaç hücre kullanılacağını byte sayısından hücre boyuna göre düşünmelidir.

## Overflow ve bounds

`#overflow wrap` taşan değeri sarar. Byte hücrede 255’ten sonra 0 gelir. `#overflow check` ise taşmayı hata olarak ele almak için kullanılır. `#bounds on` pointer ve adres sınırlarını kontrol eder; güvenli çalışma için önerilir.

```uxm
#overflow wrap
#bounds on
```

Öğrenci için pratik kural: Öğrenirken `dword`, `#bounds on`, `#overflow wrap` ile başla. Byte hücreye ancak karakter veya düşük seviyeli test yazarken geç.
