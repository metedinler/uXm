#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM-A 64K hattını açık zip klasörlerinden yeniden üretmek için yardımcı iskelet.
Kullanım:
  python build_uxm_a_64k_from_unzipped.py C:\YOL\tum_zipler_acik C:\YOL\UXM_A_64K_COMPILER
Not: Bu hazır pakette patchlenmiş iki dosya zaten vardır. Bu script, klasörleri bulup temel kopyalama mantığını tekrarlar.
"""
from pathlib import Path
import shutil, sys

def find_dir(root: Path, must_contain: str) -> Path:
    hits=[p for p in root.rglob('*') if p.is_dir() and must_contain.lower() in p.name.lower()]
    if not hits: raise SystemExit(f"Klasör bulunamadı: {must_contain}")
    return sorted(hits, key=lambda x: len(str(x)))[0]

def find_file_under(base: Path, rel_suffix: str) -> Path:
    rel_suffix=rel_suffix.replace('\\','/').lower()
    for p in base.rglob('*'):
        if p.is_file() and str(p).replace('\\','/').lower().endswith(rel_suffix): return p
    raise SystemExit(f"Dosya bulunamadı: {rel_suffix}")

def main():
    if len(sys.argv)<3:
        print(__doc__); raise SystemExit(1)
    root=Path(sys.argv[1]).resolve(); out=Path(sys.argv[2]).resolve()
    if out.exists(): shutil.rmtree(out)
    out.mkdir(parents=True)
    v20root=find_dir(root,'V20_SRC_KLASORU')
    v20=v20root/'src'
    if not (v20/'compiler/native/uxm31_compiler_fb.bas').exists():
        v20=next(p for p in v20root.rglob('src') if (p/'compiler/native/uxm31_compiler_fb.bas').exists())
    stage12=find_dir(root,'STAGE12')
    st12_native=find_file_under(stage12,'uxm/core/compiler/native/uxm31_compiler_fb.bas').parent
    shutil.copytree(v20,out/'src')
    for name in ['native_lexer_parser.bas','native_addressing.bas','native_meta_parse.bas','native_validation.bas','native_asm_emit.bas','native_main.bas']:
        shutil.copy2(st12_native/name,out/'src/compiler/native'/name)
    print('Temel kopyalama tamam. Hazır UXM_A_64K paketindeki patchlenmiş şu iki dosyayı üzerine alın:')
    print('  src/compiler/native/uxm31_compiler_fb.bas')
    print('  src/compiler/native/native_cli.bas')
    print('Ayrıca runtime_meta_dispatch.bas içindeki standalone End Extern satırını yorumlayın.')
if __name__=='__main__': main()
