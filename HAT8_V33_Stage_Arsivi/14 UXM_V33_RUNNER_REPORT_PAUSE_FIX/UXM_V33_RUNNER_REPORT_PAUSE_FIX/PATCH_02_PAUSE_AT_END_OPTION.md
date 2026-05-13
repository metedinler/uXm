# UXM V3.3 Manual EXE Pause Patch

Amaç: EXE'ye çift tıklanınca sonucu görebilmek için program sonunda tuşa basma beklemesi eklemek.

Önemli karar:
- Bu davranış varsayılan olmayacak.
- Test runner bunu kullanmayacak; yoksa 104 test tek tek beklemede kalır.
- Manuel derleme için `--pause` veya kaynak içinde `#pause` kullanılacak.

## 1) Runtime'a eklenecek fonksiyon

Dosya: `uxm/core/runtime/uxm31_runtime_fb_full.bas`

Servis include/declaration alanına ekle:

```freebasic
Extern "C"
Sub ux_pause_at_end() Export
    Print
    Print "[UXM] Program bitti. Devam etmek icin bir tusa basin..."
    Sleep
End Sub
End Extern
```

## 2) Compiler option

Compiler ana seceneklerine bir bayrak ekle:

```freebasic
Dim Shared UXM_PauseAtEnd As Integer = 0
```

CLI parse ederken:

```freebasic
If arg = "--pause" Or arg = "-p" Then UXM_PauseAtEnd = 1
If arg = "--no-pause" Then UXM_PauseAtEnd = 0
```

Kaynak pragma istenirse:

```text
#pause
#nopause
```

parse edilirken:

```freebasic
If LCase(line) = "#pause" Then UXM_PauseAtEnd = 1
If LCase(line) = "#nopause" Then UXM_PauseAtEnd = 0
```

## 3) ASM emitter cikis noktasına eklenecek

Program exit/finish etiketinden hemen once:

```asm
extern ux_pause_at_end
```

ve cikis kodundan hemen once:

```asm
    call ux_pause_at_end
```

Bunu sadece `UXM_PauseAtEnd=1` ise emit et.

Örnek FreeBASIC emitter mantığı:

```freebasic
If UXM_PauseAtEnd <> 0 Then
    EmitLine("extern ux_pause_at_end")
End If

' ... program govdesi ...

If UXM_PauseAtEnd <> 0 Then
    EmitLine("    call ux_pause_at_end")
End If
EmitLine("    ret")
```

## 4) build_one_native.bat davranışı

Mevcut test modunda pause kullanma:

```bat
.\build_one_native.bat uxm\tests\native\test05_meta_add.uxm -x
```

Manuel sonuç görmek için:

```bat
.\build_one_native.bat uxm\tests\native\test05_meta_add.uxm -x --pause
```

veya kaynak dosyaya ekle:

```text
#pause
```

## 5) Neden varsayılan değil?

Çünkü otomatik test runner EXE çıktısını yakalarken programın tuş beklemesine girmesi bütün testleri kilitler. Bu yüzden pause sadece manuel kullanımda açılır.
