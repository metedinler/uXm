#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM-A 64K merge builder.

Kullanim:
  python tools/uxm_a64_merge_builder.py C:\\UXM_TUM_ZIPLER_ACIK C:\\UXM_A_64K_COMPILER

Gorev:
  - V20 src agacini temel alir.
  - Stage12 native FreeBASIC dosyalarini secici olarak bindirir.
  - uxm31_compiler_fb.bas ve native_cli.bas dosyalarini 64 KB ana bellek kuralina gore patchler.
  - runtime_meta_dispatch.bas icindeki standalone End Extern riskini temizler.
  - test, vscode ve gate araclarini ayri klasorlere alir.

Not:
  Bu script dosya secme ve patchleme scriptidir; derleme yapmaz.
"""
from __future__ import annotations
from pathlib import Path
import csv
import datetime as _dt
import hashlib
import re
import shutil
import sys
import zipfile

NATIVE_STAGE12_FILES = [
    'native_lexer_parser.bas',
    'native_addressing.bas',
    'native_meta_parse.bas',
    'native_validation.bas',
    'native_asm_emit.bas',
    'native_main.bas',
]

TR_MAP = str.maketrans({'ı':'i','İ':'I','ğ':'g','Ğ':'G','ş':'s','Ş':'S','ç':'c','Ç':'C','ö':'o','Ö':'O','ü':'u','Ü':'U'})

def sha16(p: Path) -> str:
    if not p.exists() or not p.is_file():
        return ''
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()[:16]

def die(msg: str) -> None:
    raise SystemExit('HATA: ' + msg)

def find_dir(root: Path, needle: str) -> Path | None:
    hits = [p for p in root.rglob('*') if p.is_dir() and needle.lower() in p.name.lower()]
    return sorted(hits, key=lambda p: len(str(p)))[0] if hits else None

def find_file(root: Path, suffix: str) -> Path | None:
    suffix = suffix.replace('\\', '/').lower()
    for p in root.rglob('*'):
        if p.is_file() and str(p).replace('\\', '/').lower().endswith(suffix):
            return p
    return None

def find_v20_src(root: Path) -> Path:
    base = find_dir(root, 'V20_SRC_KLASORU')
    if not base:
        die('V20_SRC_KLASORU klasoru bulunamadi')
    direct = base / 'src'
    if (direct / 'compiler/native/uxm31_compiler_fb.bas').exists():
        return direct
    for p in base.rglob('src'):
        if (p / 'compiler/native/uxm31_compiler_fb.bas').exists():
            return p
    die('V20 src icinde compiler/native/uxm31_compiler_fb.bas bulunamadi')

def find_stage12_root(root: Path) -> Path:
    p = find_dir(root, 'STAGE12')
    if not p:
        die('STAGE12 klasoru bulunamadi')
    # dis paket klasoru veya ic UXM_V33_STAGE12 olabilir
    native = find_file(p, 'uxm/core/compiler/native/uxm31_compiler_fb.bas')
    if not native:
        die('Stage12 native compiler dosyalari bulunamadi')
    # parent of uxm folder's package root
    s = native
    for _ in range(5):
        s = s.parent
    return s

def copytree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))

def patch_compiler(stage12_compiler: Path, out_compiler: Path) -> None:
    text = stage12_compiler.read_text(encoding='utf-8', errors='ignore')
    text = re.sub(r'Const UXM_VERSION As String="[^"]*"', 'Const UXM_VERSION As String="3.3-UXM-A-64K-stage12-v20-merge"', text)
    block = re.search(r'Const UXM_DEFAULT_TAPE_KB.*?Const UXM_MEMORY_POLICY_TOTAL As Long=1\n', text, flags=re.S)
    if not block:
        die('uxm31_compiler_fb.bas memory constants block bulunamadi')
    new_block = '''Const UXM_A_MAIN_MEMORY_KB As Long=64
Const UXM_TOTAL_BYTES As Long=65536
Const UXM_DEFAULT_TAPE_KB As Long=32
Const UXM_DEFAULT_STACK_KB As Long=8
Const UXM_DEFAULT_DATA_KB As Long=24
Const UXM_DEFAULT_QUEUE_KB As Long=4
Const UXM_MAX_TAPE_KB As Long=64
Const UXM_MAX_STACK_KB As Long=64
Const UXM_MAX_DATA_KB As Long=64
Const UXM_MAX_QUEUE_KB As Long=256
Const UXM_MAX_TOTAL_KB As Long=64
Const UXM_MEMORY_POLICY_BOUNDED As Long=0
Const UXM_MEMORY_POLICY_TOTAL As Long=1
'''
    text = text[:block.start()] + new_block + text[block.end():]
    text = "' UXM-A-64K MERGED: V20 clean src + Stage12 native capability + 64 KB main memory policy\n" + text
    out_compiler.write_text(text.translate(TR_MAP), encoding='utf-8')

def patch_cli(stage12_cli: Path, out_cli: Path) -> None:
    text = stage12_cli.read_text(encoding='utf-8', errors='ignore')
    apply_new = r'''Sub ApplyMemoryModel()
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    QueueBytes=QueueKB*1024

    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If

    If TapeKB<=0 Or StackKB<=0 Or DataKB<=0 Then
        HadError=1
        ErrMsg="HATA: UXM-A 64K hattinda tape/stack/data alanlari 1 KB veya daha buyuk olmali. Tape="+Str(TapeKB)+" Stack="+Str(StackKB)+" Data="+Str(DataKB)
        Exit Sub
    End If

    If QueueKB<=0 Then QueueKB=UXM_DEFAULT_QUEUE_KB
    If QueueKB>UXM_MAX_QUEUE_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A 64K hattinda queue/fifo dis depo ust siniri " + Str(UXM_MAX_QUEUE_KB) + " KB. Verilen="+Str(QueueKB)+" KB"
        Exit Sub
    End If

    ' UXM-A kurali: ana tape+stack+data bellegi kesin olarak 64 KB kalir.
    ' FIFO/queue fiziksel deposu runtime tarafinda ayridir; UXM_TOTAL_BYTES hesabina katilmaz.
    If TapeKB+StackKB+DataKB<>UXM_A_MAIN_MEMORY_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A 64K hattinda tape+stack+data toplami 64 KB olmali. Verilen="+Str(TapeKB+StackKB+DataKB)+" KB. 16 MB/genis bellek UXM-B hattidir."
        Exit Sub
    End If

    MemoryPolicy=UXM_MEMORY_POLICY_TOTAL
    MemoryTotalLimitKB=UXM_A_MAIN_MEMORY_KB
    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize()
    StackCells=StackBytes\CellSize()
    DataCells=DataBytes\CellSize()
    QueueCells=QueueBytes\CellSize()
    If QueueCells<1 Then QueueCells=1
End Sub'''
    text = re.sub(r'Sub ApplyMemoryModel\(\).*?End Sub\s*\n\s*Sub ReadFileToSrc', lambda m: apply_new + '\n\nSub ReadFileToSrc', text, flags=re.S)
    old_total = '''                v=GetPragmaValue(low,"total")
                If v<>"" Then MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)
                v=GetPragmaValue(low,"max")
                If v<>"" Then MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)'''
    new_total = '''                v=GetPragmaValue(low,"total")
                If v<>"" Then
                    If ParseSizeKB(v,UXM_A_MAIN_MEMORY_KB)<>UXM_A_MAIN_MEMORY_KB Then
                        HadError=1
                        ErrMsg="HATA: UXM-A 64K hattinda #memory total 64KB olmalidir; genis/16MB bellek UXM-B hattidir."
                    End If
                    MemoryTotalLimitKB=UXM_A_MAIN_MEMORY_KB
                End If
                v=GetPragmaValue(low,"max")
                If v<>"" Then
                    If ParseSizeKB(v,UXM_A_MAIN_MEMORY_KB)<>UXM_A_MAIN_MEMORY_KB Then
                        HadError=1
                        ErrMsg="HATA: UXM-A 64K hattinda #memory max 64KB olmalidir; genis/16MB bellek UXM-B hattidir."
                    End If
                    MemoryTotalLimitKB=UXM_A_MAIN_MEMORY_KB
                End If'''
    text = text.replace(old_total, new_total)
    text = "' UXM-A-64K MERGED: Stage12 CLI patched to preserve 64 KB tape+stack+data main memory\n" + text
    out_cli.write_text(text.translate(TR_MAP), encoding='utf-8')

def patch_runtime_dispatch(path: Path) -> int:
    text = path.read_text(encoding='utf-8', errors='ignore')
    out = []
    removed = 0
    for line in text.splitlines():
        if line.strip().lower() == 'end extern':
            out.append("' UXM-A-64K patch: removed stray End Extern from included dispatcher")
            removed += 1
        else:
            out.append(line)
    path.write_text('\n'.join(out) + '\n', encoding='utf-8')
    return removed

def write_scripts(out: Path) -> None:
    (out / 'build_native_64k.bat').write_text(r'''@echo off
setlocal
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
if not exist build\exe mkdir build\exe
%FBC% -lang fb src\compiler\native\uxm31_compiler_fb.bas -x build\exe\uxm_a64_native.exe
if errorlevel 1 exit /b 1
echo OK: build\exe\uxm_a64_native.exe
endlocal
'''.replace('\\"','"'), encoding='utf-8')
    (out / 'build_one_64k.bat').write_text(r'''@echo off
setlocal
if "%~1"=="" (echo Kullanim: build_one_64k.bat kaynak.uxm [-x] & exit /b 1)
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
set NASM=nasm
if not exist build\exe\uxm_a64_native.exe call build_native_64k.bat
if errorlevel 1 exit /b 1
if not exist build\asm mkdir build\asm
if not exist build\obj mkdir build\obj
if not exist build\exe mkdir build\exe
set NAME=%~n1
if /I "%~2"=="-x" set NAME=program
build\exe\uxm_a64_native.exe "%~1" "build\asm\%NAME%.asm"
if errorlevel 1 exit /b 1
%NASM% -f win64 "build\asm\%NAME%.asm" -o "build\obj\%NAME%.o"
if errorlevel 1 exit /b 1
%FBC% src\runtime\uxm31_runtime_fb_full.bas "build\obj\%NAME%.o" -x "build\exe\%NAME%.exe"
if errorlevel 1 exit /b 1
"build\exe\%NAME%.exe"
endlocal
'''.replace('\\"','"'), encoding='utf-8')
    (out / 'run_native_smoke_64k.bat').write_text(r'''@echo off
setlocal
call build_native_64k.bat
if errorlevel 1 exit /b 1
for %%D in (tests\stage12_native tests\stage12_v33 tests\stage12_fp tests\stage12_matrix tests\stage12_math) do (
  if exist "%%D" for %%F in (%%D\*.uxm) do call build_one_64k.bat "%%F" -x
  if errorlevel 1 exit /b 1
)
echo OK: UXM-A 64K smoke tests finished
endlocal
'''.replace('\\"','"'), encoding='utf-8')

def write_readme(out: Path, file_count: int, issues: list[str]) -> None:
    (out / 'README_UXM_A_64K.md').write_text(f'''# UXM-A-64K Compiler Candidate

Bu paket, eldeki ziplerden **64 KB ana memory hattini bozmadan** kurulmus UXM-A aday compiler/interpreter/runtime/VSCode calisma klasorudur.

## Hat karari

- **UXM-A:** 64 KB ana bellek hatti. Bu paketin hedefi budur.
- **UXM-B:** genis/16 MB memory model hatti. Bu pakete bilerek karistirilmadi.
- **UXM-C:** IDE/VSCode/gate/arac hatti. Araclar ayri klasorlere alindi.

## Derleme

```bat
build_native_64k.bat
```

Tek dosya:

```bat
build_one_64k.bat tests\\stage12_native\\test01_print_A.uxm -x
```

Smoke:

```bat
run_native_smoke_64k.bat
```

## Kritik patchler

- `src/compiler/native/uxm31_compiler_fb.bas`: Stage12 ana compiler, 64 KB sabitleriyle patchlendi.
- `src/compiler/native/native_cli.bas`: `TapeKB+StackKB+DataKB=64` zorunlu; `queue/fifo` ana bellege katilmiyor.
- `src/runtime/runtime_meta_dispatch.bas`: standalone `End Extern` riski temizlendi.

## Statik durum

- Dosya sayisi: {file_count}
- Bu script derleme yapmaz; fbc/nasm olan Windows ortaminda derleme senin tarafinda calistirilir.
- HIR/MIR tam pipeline degil; V20 AST/semantic/codegen bridge korunmustur.

## Uyarilar

{chr(10).join('- '+i for i in issues) if issues else '- Statik patch kontrolunde kritik eksik gorunmedi.'}
''', encoding='utf-8')

def main() -> None:
    if len(sys.argv) < 3:
        print(__doc__)
        raise SystemExit(1)
    root = Path(sys.argv[1]).resolve()
    out = Path(sys.argv[2]).resolve()
    if not root.exists():
        die(f'kaynak kok klasor yok: {root}')
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    manifest = []
    def rec(action, src, dst, note):
        manifest.append({'action': action, 'source': str(src) if src else '', 'target': str(dst), 'note': note, 'sha16': sha16(Path(dst))})

    v20 = find_v20_src(root)
    stage12 = find_stage12_root(root)
    st12_native = find_file(stage12, 'uxm/core/compiler/native/uxm31_compiler_fb.bas').parent
    st12_tests = find_file(stage12, 'uxm/tests/native/test01_print_A.uxm').parents[1]
    copytree(v20, out / 'src')
    rec('BASE_COPY', v20, out / 'src', 'V20 temiz src agaci')
    for name in NATIVE_STAGE12_FILES:
        shutil.copy2(st12_native / name, out / 'src/compiler/native' / name)
        rec('OVERLAY_STAGE12_NATIVE', st12_native / name, out / 'src/compiler/native' / name, 'Stage12 native dosyasi')
    patch_compiler(st12_native / 'uxm31_compiler_fb.bas', out / 'src/compiler/native/uxm31_compiler_fb.bas')
    rec('PATCH_COMPILER_64K', st12_native / 'uxm31_compiler_fb.bas', out / 'src/compiler/native/uxm31_compiler_fb.bas', '64 KB compiler sabitleri')
    patch_cli(st12_native / 'native_cli.bas', out / 'src/compiler/native/native_cli.bas')
    rec('PATCH_CLI_64K', st12_native / 'native_cli.bas', out / 'src/compiler/native/native_cli.bas', '64 KB ApplyMemoryModel')
    removed = patch_runtime_dispatch(out / 'src/runtime/runtime_meta_dispatch.bas')
    rec('PATCH_RUNTIME_DISPATCH', out / 'src/runtime/runtime_meta_dispatch.bas', out / 'src/runtime/runtime_meta_dispatch.bas', f'End Extern temizligi removed={removed}')
    write_scripts(out)
    for n in ['build_native_64k.bat','build_one_64k.bat','run_native_smoke_64k.bat']:
        rec('CREATE_SCRIPT', None, out / n, 'UXM-A script')
    for sub, dest in [('native','stage12_native'),('v33','stage12_v33'),('fp','stage12_fp'),('matrix','stage12_matrix'),('math','stage12_math')]:
        sp = st12_tests / sub
        if sp.exists():
            copytree(sp, out / 'tests' / dest)
            rec('COPY_TESTS', sp, out / 'tests' / dest, 'Stage12 test grubu')
    optional_dirs = [
        ('FINAL_EXPECTED_TEST_SUITE', 'tests/final_expected_suite', 'final expected tests'),
        ('FINAL_RELEASE_GATE_V20_PACKAGE', 'tools/final_release_gate_v20', 'release gate'),
        ('PS1_BAT_KOMUT_ONARIM_V22', 'tools/v22_ps1_bat_fix', 'v22 scripts'),
        ('STAGE17_20_V15', 'tools/stage17_20_v15', 'v15 tools'),
    ]
    for needle, dst_rel, note in optional_dirs:
        d = find_dir(root, needle)
        if d:
            copytree(d, out / dst_rel)
            rec('COPY_OPTIONAL', d, out / dst_rel, note)
    # VSCode v15 exact artifact if found
    v15_ext = find_file(root, 'vscode/uxm-dil-destegi-v15/package.json')
    if v15_ext:
        copytree(v15_ext.parent, out / 'vscode/uxm-dil-destegi-v15')
        rec('COPY_VSCODE_V15', v15_ext.parent, out / 'vscode/uxm-dil-destegi-v15', 'VSCode extension artifact')
    # compatibility mirror
    comp = out / 'uxm/core'
    (comp / 'compiler').mkdir(parents=True, exist_ok=True)
    (comp / 'runtime').mkdir(parents=True, exist_ok=True)
    copytree(out / 'src/compiler/native', comp / 'compiler/native')
    copytree(out / 'src/compiler/extensions', comp / 'compiler/extensions')
    copytree(out / 'src/runtime', comp / 'runtime')
    rec('CREATE_COMPAT_MIRROR', out / 'src/compiler/native', comp / 'compiler/native', 'uxm/core uyum aynasi')
    rec('CREATE_COMPAT_MIRROR', out / 'src/runtime', comp / 'runtime', 'uxm/core runtime aynasi')
    for old_script in ['build_native.bat','build_one_native.bat','run_tests_native.bat']:
        p = find_file(stage12, old_script)
        if p:
            shutil.copy2(p, out / old_script)
            rec('COPY_STAGE12_SCRIPT', p, out / old_script, 'eski script uyumu')
    issues = []
    comp_text = (out / 'src/compiler/native/uxm31_compiler_fb.bas').read_text(encoding='utf-8', errors='ignore')
    cli_text = (out / 'src/compiler/native/native_cli.bas').read_text(encoding='utf-8', errors='ignore')
    rmd_text = (out / 'src/runtime/runtime_meta_dispatch.bas').read_text(encoding='utf-8', errors='ignore')
    if 'Const UXM_TOTAL_BYTES As Long=65536' not in comp_text:
        issues.append('UXM_TOTAL_BYTES=65536 bulunamadi')
    if 'TapeKB+StackKB+DataKB<>UXM_A_MAIN_MEMORY_KB' not in cli_text:
        issues.append('64 KB toplam kuralı bulunamadi')
    if any(line.strip().lower() == 'end extern' for line in rmd_text.splitlines()):
        issues.append('runtime_meta_dispatch.bas icinde standalone End Extern kaldi')
    file_count = sum(1 for p in out.rglob('*') if p.is_file())
    write_readme(out, file_count, issues)
    rec('CREATE_README', None, out / 'README_UXM_A_64K.md', 'README')
    audit = out / 'UXM_A_64K_STATIC_AUDIT.md'
    audit.write_text(f'''# UXM-A-64K Static Audit

Tarih: {_dt.datetime.now().isoformat(timespec='seconds')}

Dosya sayisi: {file_count}

Derleme calistirilmadi. fbc/nasm gereklidir.

## Issues

{chr(10).join('- '+i for i in issues) if issues else '- Kritik statik sorun yok.'}
''', encoding='utf-8')
    rec('CREATE_AUDIT', None, audit, 'static audit')
    with (out / 'UXM_A_64K_MERGE_MANIFEST.csv').open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['action','source','target','note','sha16'])
        w.writeheader(); w.writerows(manifest)
    # optional zip next to output
    zp = out.with_suffix('.zip')
    with zipfile.ZipFile(zp, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in out.rglob('*'):
            if p.is_file():
                z.write(p, out.name + '/' + str(p.relative_to(out)).replace('\\','/'))
    print('OK:', out)
    print('ZIP:', zp)
    if issues:
        print('UYARI:', issues)

if __name__ == '__main__':
    main()
