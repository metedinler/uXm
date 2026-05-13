# UXM-A-64K Compiler Candidate

Bu paket, eldeki ziplerden **64 KB ana memory hattını bozmadan** kurulmuş UXM-A aday compiler/interpreter/runtime/VSCode çalışma klasörüdür.

## Hat kararı

- **UXM-A:** 64 KB ana bellek hattı. Bu paketin hedefi budur.
- **UXM-B:** geniş/16 MB memory model hattı. Bu pakete bilinçli olarak karıştırılmadı.
- **UXM-C:** IDE/VSCode/gate/araç hattı. Araçlar ayrı klasörlere alındı.

## Temel kaynaklar

1. `52 UXM_V33_V20_SRC_KLASORU.zip` → temiz `src` mimarisi.
2. `13 UXM_V33_STAGE12_tensor_advanced2_package.zip` → gelişmiş FreeBASIC native compiler split dosyaları.
3. `24 UXM_V33_FINAL_EXPECTED_TEST_SUITE.zip` → final expected test seti.
4. `39 UXM_V33_STAGE17_20_V15_PACKAGE.zip` → VSCode artifact.
5. `47 UXM_V33_FINAL_RELEASE_GATE_V20_PACKAGE.zip` → release gate araçları.
6. `50 UXM_V33_PS1_BAT_KOMUT_ONARIM_V22_PACKAGE.zip` → BAT/PS1 araçları.

## Kritik patchler

### `src/compiler/native/uxm31_compiler_fb.bas`

Stage12 dosyası alındı; sürüm ve bellek sabitleri UXM-A için patchlendi:

```basic
Const UXM_A_MAIN_MEMORY_KB As Long=64
Const UXM_TOTAL_BYTES As Long=65536
Const UXM_DEFAULT_TAPE_KB As Long=32
Const UXM_DEFAULT_STACK_KB As Long=8
Const UXM_DEFAULT_DATA_KB As Long=24
Const UXM_DEFAULT_QUEUE_KB As Long=4
```

### `src/compiler/native/native_cli.bas`

Stage12 CLI alındı; `ApplyMemoryModel()` UXM-A için değiştirildi:

- `TapeKB + StackKB + DataKB = 64 KB` zorunlu.
- `queue/fifo` ana `UXM_TOTAL_BYTES` içine katılmaz.
- `#memory total=16mb` UXM-A hattında hata sayılır; bu UXM-B hattının konusudur.

### `src/runtime/runtime_meta_dispatch.bas`

Include edilen dosyada standalone `End Extern` satırı vardı; FreeBASIC derlemesini bozma riski nedeniyle yorumlandı.

## Derleme

Windows üzerinde kök klasörde:

```bat
build_native_64k.bat
```

Tek dosya derleme/çalıştırma:

```bat
build_one_64k.bat tests\stage12_native	est01_print_A.uxm -x
```

Stage12 smoke:

```bat
run_native_smoke_64k.bat
```

Eski Stage12 betikleri için ayrıca `uxm/core/...` uyum aynası da üretildi. Yani `build_native.bat` de denenebilir.

## Dürüst durum

Bu ortamda `fbc` ve `nasm` olmadığı için derleme çalıştırılamadı. Paket, statik merge + patch + dosya bütünlüğü kontrolüyle üretildi. Senin Windows ortamında ilk kapı şudur:

```bat
build_native_64k.bat
```

Eğer burada hata verirse ilk bakılacak dosyalar:

1. `src/compiler/native/uxm31_compiler_fb.bas`
2. `src/compiler/native/native_cli.bas`
3. `src/runtime/runtime_meta_dispatch.bas`
4. `src/runtime/uxm31_runtime_fb_full.bas`

## Mimari uyarı

Bu paket HIR/MIR katmanını tam gerçek compiler pipeline olarak üretmez. V20 `ast`, `semantic`, `codegen_bridge`, `fullcode_bridge` dosyaları korunmuştur; ama gerçek güçlü hat native compiler + runtime tarafıdır.
