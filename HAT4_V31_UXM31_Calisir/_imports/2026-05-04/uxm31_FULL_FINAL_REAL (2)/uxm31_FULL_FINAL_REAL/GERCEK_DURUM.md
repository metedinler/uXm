# UX-MINIMA V3.1 Full Final - Gerçek Durum

Bu paket, önceki boş/yanlış final dosyasının yerine hazırlanmış gerçek kaynak paketidir.

## Önemli düzeltme

Yüklenen `uxm31_compiler_final(2).bas` dosyası gerçek compiler değil, yalnızca küçük bir UXM test içeriğiydi. Bu paketteki gerçek final compiler dosyası:

```text
final/uxm31_compiler_final.bas
```

Bu dosya boş değildir ve tek merkezli ARGE compiler/tool olarak parse, diagnostics JSON, UIR JSON, optimizer raporu, interpreter/step trace, IDE JSON protokolü ve ASM emitter bölümlerini içerir.

## Bu ortamda test durumu

Bu ChatGPT ortamında `fbc` ve `nasm` kurulu olmadığı için FreeBASIC/NASM ile gerçek derleme testi yapılamadı. Bu yüzden paket kaynak düzeyinde hazırlanmıştır; Windows ortamında ilk derlemede syntax farkı çıkarsa düzeltmek gerekir.

## Ana dosyalar

```text
final/uxm31_compiler_final.bas          Final ARGE compiler/tool
runtime/uxm31_runtime_fb_full.bas       Native ASM ile linklenecek runtime
compiler/uxm31_compiler_fb.bas          Önceki native compiler hattı
tools/uxm31_full_tool_fb.bas            Interpreter/trace/full tool hattı
ide/uxminima-vscode/                    VS Code eklentisi
math_extensions/                        #poly/#expr-rpn/runtime math servis ekleri
lib/ux_math_v1.uxm                      Matematik macro header
```

## İlk deneme

```bat
build_final_compiler.bat
run_final_probe.bat
```

## Native derleme zinciri

```bat
fbc final\uxm31_compiler_final.bas -x build\uxm31_compiler_final.exe
build\uxm31_compiler_final.exe --input tests\test05_meta_add.uxm --mode compile --asm build\test05.asm --uir build\test05.uir.json --diag build\test05.diag.json --opt build\test05.opt.json
nasm -f win64 build\test05.asm -o build\test05.obj
fbc runtime\uxm31_runtime_fb_full.bas build\test05.obj -x build\test05.exe
build\test05.exe
```
