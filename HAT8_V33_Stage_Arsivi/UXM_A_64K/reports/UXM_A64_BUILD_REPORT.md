# UXM-A-64K Kurulum Raporu

Root: `C:\Users\mete\Downloads\UXMC\ucma`
Output: `C:\Users\mete\Downloads\UXMC\ucma\UXM_A_64K`

## Paketler
- stage12: `13 UXM_V33_STAGE12_tensor_advanced2_package`
- v20src: `52 UXM_V33_V20_SRC_KLASORU`
- v15tools: `39 UXM_V33_STAGE17_20_V15_PACKAGE`
- final_tests: `24 UXM_V33_FINAL_EXPECTED_TEST_SUITE`
- release_gate: `47 UXM_V33_FINAL_RELEASE_GATE_V20_PACKAGE`
- release_gate_dup: `51 UXM_V33_FINAL_RELEASE_GATE_V20_PACKAGE`
- v22_fix: `50 UXM_V33_PS1_BAT_KOMUT_ONARIM_V22_PACKAGE`

## Mimari karar
- Base: V20 temiz `src` mimarisi.
- Native compiler: Stage12 gelişmiş split dosyaları + 64KB patch.
- Runtime: V20/V18/V19 birleşik servisleri.
- Interpreter: 64KB adapter üretildi; native runtime extern sembolü yerine lokal array bellek kullanır.
- VSCode: V20 TS kaynak + varsa V15 kurulabilir artifact.

## Statik kapılar
- Eksik include sayısı: 0
- Declare edilip implementasyonu bulunmayan isim sayısı: 0
- Çift implementasyon adı sayısı: 34
- fbc bulundu mu: Evet: C:\Program Files (x86)\FreeBASIC\fbc.EXE
- nasm bulundu mu: Evet: C:\Program Files\CodeBlocks\MinGW\bin\nasm.EXE

### Çift implementasyon adları
Bunların bir kısmı bilinçli olabilir; özellikle interpreter callbackleri/runtime callbackleri ayrı hatlarda çakışabilir.
- cellbytes -> src\interpreter\interpreter_runtime_memory_64k.bas:19, src\runtime\runtime_memory.bas:18
- cellmask -> src\interpreter\interpreter_runtime_memory_64k.bas:32, src\runtime\runtime_memory.bas:31
- cellmaxsigned -> src\interpreter\interpreter_runtime_memory_64k.bas:58, src\runtime\runtime_memory.bas:57
- cellminsigned -> src\interpreter\interpreter_runtime_memory_64k.bas:71, src\runtime\runtime_memory.bas:70
- cellsignbit -> src\interpreter\interpreter_runtime_memory_64k.bas:45, src\runtime\runtime_memory.bas:44
- clampdoubletocell -> src\interpreter\interpreter_runtime_memory_64k.bas:191, src\runtime\runtime_memory.bas:190
- clamptocell -> src\interpreter\interpreter_runtime_memory_64k.bas:165, src\runtime\runtime_memory.bas:164
- database -> src\interpreter\interpreter_runtime_memory_64k.bas:15, src\runtime\runtime_memory.bas:14
- datablockclear -> src\interpreter\interpreter_runtime_memory_64k.bas:217, src\runtime\runtime_memory.bas:216
- datablockcopy -> src\interpreter\interpreter_runtime_memory_64k.bas:205, src\runtime\runtime_memory.bas:204
- fromsignedvalue -> src\interpreter\interpreter_runtime_memory_64k.bas:161, src\runtime\runtime_memory.bas:160
- linearsearchdata -> src\interpreter\interpreter_runtime_memory_64k.bas:313, src\runtime\runtime_memory.bas:312
- linearsearchtape -> src\interpreter\interpreter_runtime_memory_64k.bas:297, src\runtime\runtime_memory.bas:296
- membase -> src\interpreter\interpreter_runtime_memory_64k.bas:3, src\runtime\runtime_memory.bas:2
- readcell -> src\interpreter\interpreter_runtime_memory_64k.bas:84, src\runtime\runtime_memory.bas:83
- readdata -> src\interpreter\interpreter_runtime_memory_64k.bas:128, src\runtime\runtime_memory.bas:127
- readtape -> src\interpreter\interpreter_runtime_memory_64k.bas:112, src\runtime\runtime_memory.bas:111
- readtaperel -> src\interpreter\interpreter_runtime_memory_64k.bas:144, src\runtime\runtime_memory.bas:143
- sortdata -> src\interpreter\interpreter_runtime_memory_64k.bas:275, src\runtime\runtime_memory.bas:274
- sorttape -> src\interpreter\interpreter_runtime_memory_64k.bas:253, src\runtime\runtime_memory.bas:252
- stackbase -> src\interpreter\interpreter_runtime_memory_64k.bas:11, src\runtime\runtime_memory.bas:10
- tapebase -> src\interpreter\interpreter_runtime_memory_64k.bas:7, src\runtime\runtime_memory.bas:6
- tapeblockclear -> src\interpreter\interpreter_runtime_memory_64k.bas:241, src\runtime\runtime_memory.bas:240
- tapeblockcopy -> src\interpreter\interpreter_runtime_memory_64k.bas:229, src\runtime\runtime_memory.bas:228
- tosignedvalue -> src\interpreter\interpreter_runtime_memory_64k.bas:152, src\runtime\runtime_memory.bas:151
- ux_getc -> src\interpreter\uxm_v20_interpreter.bas:12, src\runtime\runtime_io.bas:225
- ux_print_data_string -> src\interpreter\uxm_v20_interpreter.bas:23, src\runtime\runtime_io.bas:236
- ux_putc -> src\interpreter\uxm_v20_interpreter.bas:8, src\runtime\runtime_io.bas:221
- ux_runtime_error -> src\interpreter\uxm_v20_interpreter.bas:19, src\runtime\runtime_io.bas:256
- wildlayoutchange -> src\interpreter\interpreter_runtime_memory_64k.bas:329, src\runtime\runtime_memory.bas:328
- writecell -> src\interpreter\interpreter_runtime_memory_64k.bas:97, src\runtime\runtime_memory.bas:96
- writedata -> src\interpreter\interpreter_runtime_memory_64k.bas:136, src\runtime\runtime_memory.bas:135
- writetape -> src\interpreter\interpreter_runtime_memory_64k.bas:120, src\runtime\runtime_memory.bas:119
- writetaperel -> src\interpreter\interpreter_runtime_memory_64k.bas:148, src\runtime\runtime_memory.bas:147

## Sonraki gerçek doğrulama
Windows ortamında `build_a64_gate.bat` çalıştır. Bu script önce FreeBASIC derlemesi, sonra statik 64KB kapısını çalıştırır.
