#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM-A64 mevcut çıktı onarıcı
-----------------------------
Önceki uxm_a_64k_builder.py ile üretilmiş UXM_A_64K klasörünü silmeden onarır.
Ana düzeltmeler:
- native_cli.bas: Tape+Stack+Data tam 64 KB şartı yerine <=64 KB üst sınırı
- interpreter: runtime_io ile çakışan ux_putc/ux_getc/ux_runtime_error/ux_print_data_string tekrarlarını kaldırma
- .uxma.bak dosyalarını src dışına reports/patch_backups altına taşıma
- compile-unit duplicate/include raporu üretme
"""
from __future__ import annotations
import argparse, re, shutil, json, csv
from pathlib import Path
UTF8='utf-8'

APPLY_MEMORY_MODEL = r'''Sub ApplyMemoryModel()
    ' UXM-A-64K v2: ana tape+stack+data memory 64 KB ust sinirini asamaz.
    ' Daha kucuk test/deneme layoutlari kabul edilir. Queue/FIFO fiziksel deposu
    ' UXM_TOTAL_BYTES icine katilmaz; runtime tarafinda ayri alan olarak tutulur.
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    QueueBytes=QueueKB*1024

    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If

    If TapeKB<=0 Or StackKB<=0 Or DataKB<=0 Or QueueKB<=0 Then
        HadError=1
        ErrMsg="HATA: #memory alanlari KB cinsinden 1 veya daha buyuk olmali. Tape=" & Str(TapeKB) & " Stack=" & Str(StackKB) & " Data=" & Str(DataKB) & " Queue=" & Str(QueueKB)
        Exit Sub
    End If

    If MemoryTotalLimitKB<=0 Or MemoryTotalLimitKB>UXM_MAX_TOTAL_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A-64K hattinda #memory total/max 64 KB ustune cikamaz. Verilen limit=" & Str(MemoryTotalLimitKB) & " KB"
        Exit Sub
    End If

    If TapeKB>UXM_MAX_TAPE_KB Or StackKB>UXM_MAX_STACK_KB Or DataKB>UXM_MAX_DATA_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A-64K hattinda tape/stack/data alanlari ayri ayri 64 KB ustune cikamaz. Tape=" & Str(TapeKB) & " Stack=" & Str(StackKB) & " Data=" & Str(DataKB)
        Exit Sub
    End If

    If QueueKB>UXM_MAX_QUEUE_KB Then
        HadError=1
        ErrMsg="HATA: queue/fifo fiziksel ust siniri " & Str(UXM_MAX_QUEUE_KB) & " KB. Verilen=" & Str(QueueKB) & " KB."
        Exit Sub
    End If

    If TapeKB+StackKB+DataKB>MemoryTotalLimitKB Then
        HadError=1
        ErrMsg="HATA: UXM-A-64K hattinda Tape+Stack+Data toplamı limit ustune cikamaz. Toplam=" & Str(TapeKB+StackKB+DataKB) & " KB Limit=" & Str(MemoryTotalLimitKB) & " KB. Queue/FIFO bu toplama dahil degildir."
        Exit Sub
    End If

    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize()
    StackCells=StackBytes\CellSize()
    DataCells=DataBytes\CellSize()
    QueueCells=QueueBytes\CellSize()
    If QueueCells<1 Then QueueCells=1
End Sub'''

def read(p: Path) -> str:
    return p.read_text(encoding=UTF8, errors='ignore')

def write_backup_and_replace(root: Path, p: Path, new_text: str, actions: list[dict], note: str):
    old = read(p)
    if old == new_text:
        actions.append({'file': str(p.relative_to(root)), 'action': 'NO_CHANGE', 'note': note})
        return
    bak = root/'reports/patch_backups'/p.relative_to(root).with_suffix(p.suffix+'.before_repair.bak')
    bak.parent.mkdir(parents=True, exist_ok=True)
    if not bak.exists():
        bak.write_text(old, encoding=UTF8, newline='\n')
    p.write_text(new_text, encoding=UTF8, newline='\n')
    actions.append({'file': str(p.relative_to(root)), 'action': 'PATCH', 'note': note, 'backup': str(bak.relative_to(root))})

def patch_native_cli(root: Path, actions: list[dict]):
    p = root/'src/compiler/native/native_cli.bas'
    if not p.exists():
        actions.append({'file':'src/compiler/native/native_cli.bas','action':'MISSING','note':'native_cli bulunamadı'})
        return
    txt = read(p)
    txt = re.sub(r'Sub\s+ApplyMemoryModel\(\).*?\nEnd Sub\s*\n\s*Sub\s+ReadFileToSrc',
                 lambda m: APPLY_MEMORY_MODEL + '\n\nSub ReadFileToSrc', txt, flags=re.S|re.I, count=1)
    txt = re.sub(
        r'If\s+MemoryTotalLimitKB<>UXM_TOTAL_KB\s+Then\s*\n\s*HadError=1\s*\n\s*ErrMsg="HATA: UXM-A-64K hattinda #memory total/max sadece 64KB olabilir\. Verilen="\+Str\(MemoryTotalLimitKB\)\+" KB"\s*\n\s*Exit Sub\s*\n\s*End If',
        '''If MemoryTotalLimitKB<=0 Or MemoryTotalLimitKB>UXM_MAX_TOTAL_KB Then
                        HadError=1
                        ErrMsg="HATA: UXM-A-64K hattinda #memory total/max 64KB ustune cikamaz. Verilen=" & Str(MemoryTotalLimitKB) & " KB"
                        Exit Sub
                    End If''',
        txt, flags=re.I)
    write_backup_and_replace(root, p, txt, actions, 'ApplyMemoryModel exact 64KB yerine <=64KB üst sınırı yapıldı')

def patch_interpreter(root: Path, actions: list[dict]):
    p = root/'src/interpreter/uxm_v20_interpreter.bas'
    if not p.exists():
        actions.append({'file':'src/interpreter/uxm_v20_interpreter.bas','action':'MISSING','note':'interpreter bulunamadı'})
        return
    txt = read(p)
    txt = txt.replace('#Include Once "../runtime/uxm31_runtime_fb_full.bas"', '#Include Once "interpreter_runtime_adapter_64k.bas"')
    for name, endkw in [('ux_putc','End Sub'), ('ux_getc','End Function'), ('ux_runtime_error','End Sub'), ('ux_print_data_string','End Sub')]:
        txt = re.sub(r'(?is)\n\s*(?:Sub|Function)\s+' + name + r'\b.*?' + endkw + r'\s*', '\n', txt, count=1)
    txt = re.sub(r'Const\s+UXM_INTERP_MEM_BYTES\s+As\s+ULongInt\s*=\s*16UL\s*\*\s*1024UL\s*\*\s*1024UL\s*\n.*?Dim\s+Shared\s+ux_data_offset\s+As\s+ULong\s*=\s*1048576\s*\+\s*262144\s*\n',
                 "' UXM-A-64K: bellek ve runtime servis bağlantısı interpreter_runtime_adapter_64k.bas içinde tanımlanır.\n", txt, flags=re.S|re.I)
    write_backup_and_replace(root, p, txt, actions, 'runtime_io ile çakışan interpreter callback tekrarları kaldırıldı')

def move_src_backups(root: Path, actions: list[dict]):
    for p in list((root/'src').rglob('*.uxma.bak')):
        dst = root/'reports/patch_backups'/p.relative_to(root/'src')
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            p.unlink()
            actions.append({'file': str(p.relative_to(root)), 'action':'REMOVE_DUP_BACKUP', 'note':str(dst.relative_to(root))})
        else:
            shutil.move(str(p), str(dst))
            actions.append({'file': str(p.relative_to(root)), 'action':'MOVE_BACKUP', 'note':str(dst.relative_to(root))})

def compile_unit_report(root: Path, actions: list[dict]):
    inc_re = re.compile(r'(?im)^\s*#Include(?:\s+Once)?\s+"([^"]+)"')
    fn_re = re.compile(r'(?im)^\s*(?:Export\s+)?(?:Sub|Function)\s+([A-Za-z_][A-Za-z0-9_]*)\b')
    def collect(file: Path, seen=None):
        if seen is None: seen=set()
        file=file.resolve()
        if file in seen: return []
        seen.add(file)
        files=[file]
        txt=read(file)
        for inc in inc_re.findall(txt):
            target=(file.parent/inc).resolve()
            if target.exists(): files += collect(target, seen)
        return files
    report=[]
    for entry in ['src/uxm_v20_native_compiler.bas','src/uxm_v20_runtime.bas','src/interpreter/uxm_v20_interpreter.bas']:
        f=root/entry
        if not f.exists():
            report.append({'entry':entry,'status':'MISSING','files':0,'duplicates':0,'duplicate_names':''})
            continue
        files=collect(f)
        impl={}
        for file in files:
            for i,line in enumerate(read(file).splitlines(),1):
                if line.lstrip().lower().startswith('declare'): continue
                m=fn_re.match(line)
                if m: impl.setdefault(m.group(1).lower(),[]).append(f'{file.relative_to(root)}:{i}')
        dups={k:v for k,v in impl.items() if len(v)>1}
        report.append({'entry':entry,'status':'OK','files':len(files),'duplicates':len(dups),'duplicate_names':'; '.join(sorted(dups)[:20])})
    out=root/'reports/UXM_A64_COMPILE_UNIT_DUPLICATES.csv'
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('w', encoding='utf-8-sig', newline='') as f:
        w=csv.DictWriter(f, fieldnames=['entry','status','files','duplicates','duplicate_names']); w.writeheader(); w.writerows(report)
    actions.append({'file':str(out.relative_to(root)), 'action':'WRITE_REPORT', 'note':'Compile-unit duplicate raporu üretildi'})

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--target', default='UXM_A_64K', help='Onarılacak UXM_A_64K klasörü')
    args=ap.parse_args()
    root=Path(args.target).resolve()
    if not (root/'src').exists():
        raise SystemExit(f'HATA: src klasörü bulunamadı: {root}')
    actions=[]
    patch_native_cli(root, actions)
    patch_interpreter(root, actions)
    move_src_backups(root, actions)
    compile_unit_report(root, actions)
    rep=root/'reports/UXM_A64_REPAIR_REPORT.json'
    rep.parent.mkdir(parents=True, exist_ok=True)
    rep.write_text(json.dumps(actions, indent=2, ensure_ascii=False), encoding=UTF8)
    print(f'OK: onarım tamamlandı. Rapor: {rep}')

if __name__ == '__main__':
    main()
