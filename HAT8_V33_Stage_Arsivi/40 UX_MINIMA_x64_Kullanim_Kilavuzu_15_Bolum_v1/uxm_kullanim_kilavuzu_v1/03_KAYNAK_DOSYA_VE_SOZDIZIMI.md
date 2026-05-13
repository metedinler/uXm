# Bölüm 3 — UXM Kaynak Dosyası, Direktifler ve Temel Sözdizimi

UXM kaynak dosyası genellikle `.uxm` uzantılı düz metin dosyasıdır. Bu dosyanın içinde iki tür bilgi bulunur: derleyiciye ayar veren **direktifler** ve programın gerçekten çalıştıracağı **komutlar**. Direktifler çoğunlukla `#` ile başlar; örneğin `#cell dword`, `#memory data=4mb`, `#overflow wrap`. Komutlar ise küçük semboller ve servis çağrılarıdır; örneğin `+`, `-`, `>`, `<`, `.`, `[ ]`, `@20`.

Bir UXM dosyasını, BASIC’teki gibi satır satır emirler listesi olarak değil, “bellek üzerinde çalışan küçük bir makine tarifi” olarak düşün. Her sembol bir işlem yapar. `+` aktif hücreyi artırır, `-` azaltır, `>` pointer’ı sağa, `<` sola taşır, `.` aktif değeri yazdırır. `@N` ise N numaralı meta servisi çağırır.

## Basit kaynak dosya iskeleti

```uxm
#cell dword
#memory total=16mb,tape=1mb,stack=256kb,data=4mb,fifo=1mb
#mode normal
#bounds on
#overflow wrap

+++++.
```

Bu örnekte hücre tipi `dword` seçilir. Toplam bellek 16 MB olarak düzenlenir. Tape, stack, data ve FIFO alanları ayrı ayrı ayarlanır. Program kısmındaki `+++++.` ise aktif hücreyi 5 yapar ve yazdırır.

## Direktifler

| Direktif | Görev | Örnek |
|---|---|---|
| `#cell` | Hücre tipini seçer: byte, word, dword | `#cell dword` |
| `#memory` | Tape, stack, data, FIFO ve toplam bellek ayarı | `#memory total=16mb,data=4mb` |
| `#mode` | Safe/normal/wild çalışma modu | `#mode normal` |
| `#bounds` | Pointer sınır kontrolü | `#bounds on` |
| `#overflow` | Taşma davranışı: wrap/check | `#overflow wrap` |
| `#compare` | signed/unsigned karşılaştırma | `#compare signed` |
| `#endian` | little/big endian veri düzeni | `#endian little` |
| `#seed` | random servisleri için başlangıç tohumu | `#seed 1234` |
| `#arge` | trace/watch/json gibi ARGE çıktılarını açar | `#arge trace watch` |

## Programcı gözüyle dosya bölümleri

UXM dosyasında önce “makinem nasıl çalışacak?” sorusunun cevabı verilir. Hücre boyu ne? Bellek ne kadar? Pointer sınırı kontrol edilecek mi? Taşma olursa wrap mi yapılacak hata mı verilecek? Sonra “bu makine ne yapacak?” sorusunun cevabı gelen komutlarla yazılır.

Kaynak dosya derlendiğinde compiler bu ayarları okuyup assembly üretir. Assembly, NASM ile object dosyasına çevrilir. FreeBASIC runtime ile linklenir ve executable dosya oluşur. Test runner da `.expect` dosyasıyla program çıktısını karşılaştırır.
