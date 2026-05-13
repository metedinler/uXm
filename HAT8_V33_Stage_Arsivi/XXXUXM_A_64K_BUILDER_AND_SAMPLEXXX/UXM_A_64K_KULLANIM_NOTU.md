# UXM-A-64K Kurucu Kullanım Notu

Bu klasördeki `uxm_a_64k_builder.py`, açık zip klasörlerinden 64 KB memory hattı için seçici birleşim yapar.

## Beklenen düzen

`uçma` klasöründe iç zipler kendi adlarıyla açık olmalı. Örnek:

```text
uçma/
  13 UXM_V33_STAGE12_tensor_advanced2_package/
  24 UXM_V33_FINAL_EXPECTED_TEST_SUITE/
  39 UXM_V33_STAGE17_20_V15_PACKAGE/
  47 UXM_V33_FINAL_RELEASE_GATE_V20_PACKAGE/
  50 UXM_V33_PS1_BAT_KOMUT_ONARIM_V22_PACKAGE/
  52 UXM_V33_V20_SRC_KLASORU/
  uxm_a_64k_builder.py
```

## Çalıştırma

```bat
cd /d C:\YOL\ucma
python uxm_a_64k_builder.py --root . --out UXM_A_64K --force
```

Linux/macOS için:

```bash
python3 uxm_a_64k_builder.py --root . --out UXM_A_64K --force
```

## Üretilen yapı

```text
UXM_A_64K/
  src/
    compiler/native/
    compiler/lexer/
    compiler/parser/
    compiler/ast/
    compiler/semantic/
    compiler/codegen/
    interpreter/
    runtime/
    shared/
    vscode/
  tests/final_expected/
  tools/release_gate_v20/
  tools/ps1_bat_fix_v22/
  tools/vscode_release/
  reports/
  build_a64_gate.bat
```

## Otomatik yapılan kritik kod değişiklikleri

1. `src/compiler/native/uxm31_compiler_fb.bas`
   - Stage12 gelişmiş native compiler deklarasyonlarını korur.
   - `UXM_TOTAL_BYTES=65536` ve `UXM_TOTAL_KB=64` ekler.
   - Varsayılan alanları `Tape=32 KB`, `Stack=8 KB`, `Data=24 KB`, `Queue=4 KB` yapar.

2. `src/compiler/native/native_cli.bas`
   - `Tape + Stack + Data = 64 KB` invariantını zorunlu yapar.
   - Queue/FIFO’yu ana 64 KB toplamına katmaz.
   - `#memory total/max` 64 KB dışında verilirse hata üretir.

3. `src/runtime/runtime_meta_dispatch.bas`
   - Tek başına duran `End Extern` satırını kaldırır.

4. `src/interpreter/uxm_v20_interpreter.bas`
   - 16 MB memory sabitini kaldırır.
   - `interpreter_runtime_adapter_64k.bas` ile 64 KB array belleğe bağlar.
   - `interpreter_runtime_memory_64k.bas` üretir; runtime memory pointerlarını `@ux_mem(0)` biçimine çevirir.

## Kontrol

Üretimden sonra:

```bat
cd /d UXM_A_64K
build_a64_gate.bat
```

Bu bat dosyası FreeBASIC derlemesi ve statik 64 KB kapısını çalıştırır. Bu ortamda `fbc` ve `nasm` olmadığı için gerçek derleme burada yapılmadı; program statik olarak test edildi.
