# Bölüm 4 — Sistem Mimarisi, Artifact ve Derleme Akışı

UXM mimarisi birden fazla katmandan oluşur. En üstte `.uxm` kaynak dosyası vardır. Bu dosya lexer/parser tarafından okunur. Direktifler configuration alanına, komutlar ise iç temsil veya doğrudan assembly emit hattına gider. Meta servisler runtime tarafındaki dispatch fonksiyonlarına bağlanır. Sonuçta `.asm`, `.obj`, `.exe`, `.json`, `.csv` ve `.md` gibi artifact dosyaları üretilebilir.

## Büyük akış grafiği

```text
UXM kaynak dosyası (.uxm)
        |
        v
Lexer / Parser
        |
        +--> Direktifler: #cell, #memory, #mode, #bounds
        |
        +--> Komutlar: + - < > . [ ] @N @(ADDR)
        |
        v
Native compile planı
        |
        +--> Adresleme çözümü
        +--> Meta servis çözümü
        +--> Güvenlik/validasyon
        |
        v
x64 NASM codegen
        |
        v
ASM çıkışı (.asm)
        |
        v
NASM assembler
        |
        v
OBJ çıkışı (.obj)
        |
        v
FreeBASIC runtime link
        |
        v
EXE programı (.exe)
        |
        +--> çalışma çıktısı
        +--> test CSV
        +--> RAPOR.md
        +--> trace/json/diagnostic artifactleri
```

## Artifact ne demek?

Artifact, derleme veya test sürecinde üretilen ara veya son dosyadır. UXM’de en önemli artifactler şunlardır:

| Artifact | Görev |
|---|---|
| `.uxm` | Kaynak program. Programcı bunu yazar. |
| `.asm` | Compiler’ın ürettiği x64 assembly dosyası. |
| `.obj` | NASM tarafından üretilen object dosyası. |
| `.exe` | Link sonrası çalıştırılabilir program. |
| `.expect` | Testte beklenen çıktı. |
| `.csv` | Test sonucu veya servis tablosu. |
| `.json` | Makinece okunabilir rapor/konfigürasyon. |
| `.md` | İnsan için okunabilir rapor/dokümantasyon. |

## Derleme sırasında görülen bilgi satırları

Runner veya compiler çıktısında şu tip alanlar görülür:

```text
Kaynak dosya:        uxm/tests/ornek.uxm
ASM cikis dosyasi:   build/asm/program.asm
Hucre tipi:          dword
Tape boyutu KB:      1024
Private stack KB:    256
Overflow modu:       wrap
Pointer sinir kontrolu: on
```

Bu alanlar programın nasıl derlendiğini anlamak için kullanılır. Özellikle hata ayıklarken hücre tipi ve memory ayarları çok önemlidir. Byte hücreyle 1048576 yazdırmaya çalışırsan değer kırpılır; dword hücreyle aynı değer doğru görünebilir.

## Mimari katmanlar

| Katman | Görev | Girdi | Çıktı |
|---|---|---|---|
| CLI | Komut satırı seçeneklerini okur | `.uxm`, `--out`, `--cell`, `--memory` | compile config |
| Lexer/Parser | Kaynak metni token ve komutlara böler | `.uxm` metni | komut listesi |
| Directive parser | `#memory`, `#cell`, `#mode` okur | direktif satırları | runtime/compile ayarı |
| Addressing resolver | `(T+1)`, `(D:5)`, `(S:0)` çözer | adresleme metni | hedef adres planı |
| Validation | sınır, mod, izin ve syntax kontrolü | komut planı | hata veya geçiş |
| Codegen | x64 NASM üretir | komut planı | `.asm` |
| Assembler | NASM ile obj üretir | `.asm` | `.obj` |
| Runtime linker | runtime servisleriyle bağlar | `.obj`, runtime | `.exe` |
| Runner | exe çalıştırır ve expect ile karşılaştırır | `.exe`, `.expect` | rapor |

## Beklenen dış fonksiyonlar

Runtime servisleri genelde `ux_meta_call_ex`, memory okuma/yazma, status flag fonksiyonları, FIFO/data/tape yardımcıları ve print yordamları gibi dış fonksiyonlar bekler. Codegen tarafı bu runtime sembollerini çağıracak assembly üretir. Bu yüzden runtime ile codegen aynı ABI üzerinde anlaşmalıdır.
