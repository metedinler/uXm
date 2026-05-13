# UXM-A 64 KB v2 Derleme Düzeltme ve Parity Yol Haritası

Bu belge, ilk `uxm_a_64k_builder.py` ile kurulan hatta görülebilecek derleme sorunlarını düzeltmek ve tüm katmanlarda parity eşitliğine doğru ilerlemek için hazırlandı.

## 1. Ana derleme sorunu: 64 KB yanlış yorumlandı

İlk planda `TapeKB + StackKB + DataKB = 64 KB` şartı konmuştu. Bu fazla sertti. Stage12 ve final expected testlerinde çok sayıda geçerli küçük layout var:

```text
#memory tape=8,stack=4,data=4
#memory tape=16,stack=4,data=32
#memory tape=32,stack=4,data=16,queue=4
```

Bunlar 64 KB hattını bozmaz; sadece 64 KB altında çalışırlar. Bu yüzden doğru kural şu olmalı:

```text
TapeKB + StackKB + DataKB <= 64 KB
Queue/FIFO bu toplama dahil değildir.
#memory total/max varsa 64 KB üstüne çıkamaz.
```

## 2. Küçük kod değişikliği 1

Klasör:

```text
src/compiler/native
```

Dosya:

```text
native_cli.bas
```

Eski mantık:

```freebasic
If TapeKB+StackKB+DataKB<>UXM_TOTAL_KB Then
    HadError=1
    ErrMsg="HATA: UXM-A-64K hattinda Tape+Stack+Data tam 64 KB olmali..."
    Exit Sub
End If
```

Yeni mantık:

```freebasic
If TapeKB+StackKB+DataKB>MemoryTotalLimitKB Then
    HadError=1
    ErrMsg="HATA: UXM-A-64K hattinda Tape+Stack+Data toplamı limit ustune cikamaz. Toplam=" & Str(TapeKB+StackKB+DataKB) & " KB Limit=" & Str(MemoryTotalLimitKB) & " KB. Queue/FIFO bu toplama dahil degildir."
    Exit Sub
End If
```

Ayrıca `#memory total/max` kontrolü de sadece `64 KB üstü` için hata vermelidir.

## 3. Küçük kod değişikliği 2

Klasör:

```text
src/interpreter
```

Dosya:

```text
uxm_v20_interpreter.bas
```

Sorun:

`interpreter_runtime_adapter_64k.bas`, runtime servislerini ve `runtime_io.bas` içindeki şu fonksiyonları zaten getiriyor:

```text
ux_putc
ux_getc
ux_runtime_error
ux_print_data_string
```

İlk kurucuda `uxm_v20_interpreter.bas` içinde bu fonksiyonlar tekrar kalıyordu. Bu, FreeBASIC derlemede çift tanım hatasına yol açabilir.

Silinecek bloklar:

```freebasic
Sub ux_putc(...)
...
End Sub

Function ux_getc() As ULongInt
...
End Function

Sub ux_runtime_error(...)
...
End Sub

Sub ux_print_data_string(...)
...
End Sub
```

Kalacak blok:

```freebasic
Sub uxm_entry() Export
End Sub
```

## 4. Küçük kod değişikliği 3

İlk kurucu patch backup dosyalarını `src` altında bırakıyordu:

```text
*.uxma.bak
```

Bu dosyalar doğrudan derlemeyi bozmaz; fakat statik tarama, duplicate analiz ve Copilot/VSCode taraması için kirlilik oluşturur. Yeni program bunları şuraya taşır:

```text
reports/patch_backups/
```

## 5. Test/gate düzeltmesi

Yeni kurucu üç tür test kopyalar:

```text
tests/final_expected_all
```

Final expected test suite’in tümü.

```text
tests/a64_selected_final_expected
```

`Tape+Stack+Data <= 64 KB` olan A64 uyumlu seçilmiş testler.

```text
tests/quarantine_over64_final_expected
```

A64 hattı için bellek üst sınırını aşan testler. Bunlar silinmez; sadece ayrı tutulur.

Ayrıca:

```text
tests/stage12_all
tests/a64_smoke_from_stage12
tests/v19_runtime_services
```

klasörleri de oluşturulur.

## 6. Yeni gate araçları

Yeni builder şu dosyaları üretir:

```text
tools/uxm_a64_static_gate.py
tools/uxm_a64_compile_gate.py
tools/uxm_a64_expected_runner.py
build_a64_gate.bat
```

Çalıştırma:

```bat
cd /d UXM_A_64K
build_a64_gate.bat
```

Bu sıra şunu yapar:

```text
1. Static gate: include, placeholder, 64 KB üst sınır kontrolü
2. FreeBASIC compile gate: native compiler + runtime + interpreter
3. A64 uyumlu seçilmiş testlerde ASM üretim denemesi
```

## 7. Katman parity durumu

| Katman | Şu anki gerçek durum | Parity için karar |
|---|---|---|
| Native compiler | Stage12 split dosyaları en güçlü hat | A64 memory patch ile korunacak |
| Runtime | V20 içinde V18/V19 servisleri birleşmiş | Runtime ana servis otoritesi V20 kalacak |
| Interpreter | V20 AST walker var ama runtime bağlantısı sorunluydu | Adapter + duplicate callback temizliği yapıldı |
| AST/parser/semantic | V20’de minimal, native parser ile eşit değil | Şimdilik deneysel/bridge katmanı sayılacak |
| MIR/HIR | Gerçek MIR/HIR dosya hattı yok | Parity belgesi üretilecek; sonraki hamlede tasarlanacak |
| VSCode | V20 `extension.ts` kaynak, V15 JS artifact operasyonel | İkisi ayrılacak: TS kaynak, JS release artifact |
| Test/gate | Testler vardı ama 64 KB’ye göre ayrılmamıştı | Yeni builder sınıflandırıyor |

## 8. Program seçimi

Sıfırdan tekrar kurulum:

```bat
python uxm_a_64k_builder_v2.py --root . --out UXM_A_64K --force
```

Mevcut eski çıktıyı silmeden onarma:

```bat
python uxm_a64_repair_existing.py --target UXM_A_64K
```

## 9. Derleme hatası devam ederse

Yeni sistem logları şuraya yazar:

```text
reports/compile_logs/
reports/UXM_A64_STATIC_GATE.txt
reports/UXM_A64_COMPILE_UNIT_DUPLICATES.csv
reports/asm_generation_logs/
```

Sonraki düzeltmede özellikle şu dosyaların logları incelenmelidir:

```text
reports/compile_logs/step_1_uxm_v20_native_compiler.log
reports/compile_logs/step_2_uxm_v20_runtime.log
reports/compile_logs/step_3_uxm_v20_interpreter.log
```
