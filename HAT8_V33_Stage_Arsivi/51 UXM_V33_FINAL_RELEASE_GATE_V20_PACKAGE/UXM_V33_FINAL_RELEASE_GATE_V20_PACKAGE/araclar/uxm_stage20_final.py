# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, hashlib, json, os, re, subprocess, sys, time
from pathlib import Path
from typing import Dict, List, Tuple, Iterable, Set

TEXT_EXTS = {'.bas','.fbs','.bi','.py','.bat','.ps1','.md','.txt','.json','.csv','.uxm','.expect','.yml','.yaml','.toml'}
CODE_EXTS = {'.bas','.fbs','.bi','.py','.bat','.ps1'}
IGNORE_DIRS = {'.git','__pycache__','build','Emekliler','emekliler','node_modules','.vscode','sonuclar_bellek','sonuclar_tum','sonuclar_hatali','hizli_sonuclar','expected_results_v2','expected_results_v3','expected_results_v4','expected_results_v5','fast_results','stage20_release','stage20_final_reports','workspace_clean_reports','mismatch_fix_reports','mismatch_diagnostics'}
FAIL_PATTERNS = [
    r'\bplaceholder\b', r'place\s*holder', r'\bdummy\b', r'\bstub\b', r'\bTODO\b',
    r'not\s+implemented', r'hen[üu]z\s+yok', r'sahte\s+sonu[cç]', r'fake\s+result',
    r'ge[çc]ici\s+d[öo]n', r'yalandan', r'pass\s*through\s*stub'
]
WARN_PATTERNS = [r'\breserved\b', r'\brezerve\b', r'planland[ıi]', r'taslak']

SERVICE_RE = re.compile(r'@!?([0-9]{1,4})')
CASE_RE = re.compile(r'(?im)^\s*(?:case|Case)\s+([0-9]{1,4})\b')
FUNC_SERVICE_RE = re.compile(r'(?i)(?:service|servis)[_a-zA-Z]*[_\s]*([0-9]{1,4})')


def now_stamp() -> str:
    return time.strftime('%Y%m%d_%H%M%S')


def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding='utf-8-sig', errors='replace')
    except Exception:
        try:
            return p.read_text(encoding='cp1254', errors='replace')
        except Exception:
            return ''


def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')


def write_csv(p: Path, rows: List[dict], fields: List[str]) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open('w', encoding='utf-8-sig', newline='') as f:
        wr = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
        wr.writeheader()
        wr.writerows(rows)


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    try:
        h.update(p.read_bytes())
        return h.hexdigest()
    except Exception:
        return ''


def iter_files(root: Path, exts: Set[str] | None = None) -> Iterable[Path]:
    for p in root.rglob('*'):
        if not p.is_file():
            continue
        rel_parts = set(p.relative_to(root).parts[:-1])
        if rel_parts & IGNORE_DIRS:
            continue
        if exts is not None and p.suffix.lower() not in exts:
            continue
        yield p


def out_dir(root: Path, name: str) -> Path:
    p = root / 'stage20_final_reports' / now_stamp() / name
    p.mkdir(parents=True, exist_ok=True)
    return p


def placeholder_scan(root: Path, include_docs: bool=False, strict_reserved: bool=False) -> Tuple[int, Path]:
    out = out_dir(root, 'placeholder_kapi')
    exts = TEXT_EXTS if include_docs else CODE_EXTS
    fail_re = re.compile('|'.join(FAIL_PATTERNS), re.I | re.U)
    warn_re = re.compile('|'.join(WARN_PATTERNS), re.I | re.U)
    rows = []
    for p in iter_files(root, exts):
        txt = read_text(p)
        if not txt:
            continue
        for i, line in enumerate(txt.splitlines(), 1):
            clean = line.strip()
            if not clean:
                continue
            # Rapor/araç dosyalarının kendi açıklamalarındaki kelimeleri kırmızıya düşürmemek için bu dosyanın kendisini es geç.
            if p.name == 'uxm_stage20_final.py':
                continue
            m = fail_re.search(clean)
            if m:
                rows.append({'seviye':'HATA','dosya':str(p.relative_to(root)),'satir':i,'anahtar':m.group(0),'icerik':clean[:300]})
                continue
            w = warn_re.search(clean)
            if w:
                sev = 'HATA' if strict_reserved else 'UYARI'
                rows.append({'seviye':sev,'dosya':str(p.relative_to(root)),'satir':i,'anahtar':w.group(0),'icerik':clean[:300]})
    fields = ['seviye','dosya','satir','anahtar','icerik']
    write_csv(out/'placeholder_bulgular.csv', rows, fields)
    hata = sum(1 for r in rows if r['seviye']=='HATA')
    uyari = sum(1 for r in rows if r['seviye']=='UYARI')
    md = ['# Stage-20 Placeholder / Dummy / TODO Kapısı','',f'- Hata: {hata}',f'- Uyarı: {uyari}',f'- Rapor: `{out}`','', '## Karar', 'GEÇTİ' if hata == 0 else 'KALDI']
    write_text(out/'RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return (1 if hata else 0), out


def parse_registry(root: Path) -> Dict[int, List[str]]:
    regs: Dict[int, List[str]] = {}
    candidates = []
    for pat in ['**/*service*registry*.csv','**/*servis*.csv','**/gerceklesen_servisler*.csv','uxm_registry_output/service_registry_merged.csv']:
        candidates.extend(root.glob(pat))
    seen = set()
    for p in candidates:
        if not p.is_file() or str(p) in seen:
            continue
        seen.add(str(p))
        try:
            with p.open('r', encoding='utf-8-sig', newline='') as f:
                rd = csv.DictReader(f)
                if not rd.fieldnames:
                    continue
                for row in rd:
                    blob = ' '.join(str(v) for v in row.values() if v is not None)
                    for m in SERVICE_RE.finditer(blob):
                        n = int(m.group(1))
                        regs.setdefault(n, []).append(str(p.relative_to(root)))
        except Exception:
            txt = read_text(p)
            for m in SERVICE_RE.finditer(txt):
                n = int(m.group(1))
                regs.setdefault(n, []).append(str(p.relative_to(root)))
    return regs


def parse_dispatch(root: Path) -> Dict[int, List[str]]:
    disp: Dict[int, List[str]] = {}
    for p in iter_files(root, {'.bas','.fbs','.bi'}):
        txt = read_text(p)
        for m in CASE_RE.finditer(txt):
            n = int(m.group(1)); disp.setdefault(n, []).append(str(p.relative_to(root)))
        for m in FUNC_SERVICE_RE.finditer(txt):
            n = int(m.group(1)); disp.setdefault(n, []).append(str(p.relative_to(root)))
    return disp


def parse_tests(root: Path) -> Dict[int, List[str]]:
    refs: Dict[int, List[str]] = {}
    for p in iter_files(root, {'.uxm'}):
        txt = read_text(p)
        for m in SERVICE_RE.finditer(txt):
            n=int(m.group(1)); refs.setdefault(n, []).append(str(p.relative_to(root)))
    return refs


def service_alignment(root: Path, fail_on_registry_missing_dispatch: bool=True) -> Tuple[int, Path]:
    out = out_dir(root, 'servis_uyum')
    regs, disp, tests = parse_registry(root), parse_dispatch(root), parse_tests(root)
    all_ids = sorted(set(regs)|set(disp)|set(tests))
    rows=[]
    for n in all_ids:
        in_reg = n in regs; in_disp = n in disp; in_tests = n in tests
        durum = 'TAM'
        if in_reg and not in_disp:
            durum = 'REGISTRY_VAR_DISPATCH_YOK'
        elif in_disp and not in_reg:
            durum = 'DISPATCH_VAR_REGISTRY_YOK'
        elif in_disp and not in_tests:
            durum = 'TEST_YOK'
        rows.append({
            'servis': n,
            'durum': durum,
            'registry': '; '.join(sorted(set(regs.get(n, [])))[:5]),
            'dispatch': '; '.join(sorted(set(disp.get(n, [])))[:5]),
            'test': '; '.join(sorted(set(tests.get(n, [])))[:5]),
        })
    write_csv(out/'servis_uyum.csv', rows, ['servis','durum','registry','dispatch','test'])
    critical = [r for r in rows if r['durum']=='REGISTRY_VAR_DISPATCH_YOK'] if fail_on_registry_missing_dispatch else []
    dup_rows=[]
    for n, files in disp.items():
        if len(set(files)) > 1:
            dup_rows.append({'servis':n,'dispatch_adet':len(set(files)),'dosyalar':'; '.join(sorted(set(files))[:10])})
    write_csv(out/'servis_dispatch_coklu.csv', dup_rows, ['servis','dispatch_adet','dosyalar'])
    md = ['# Stage-20 Servis Tablosu / Runtime Dispatch Uyumu','',f'- Registry servis adedi: {len(regs)}',f'- Dispatch servis adedi: {len(disp)}',f'- Testlerde görülen servis adedi: {len(tests)}',f'- Kritik registry var ama dispatch yok: {len(critical)}',f'- Çoklu dispatch uyarısı: {len(dup_rows)}',f'- Rapor: `{out}`','', '## Karar', 'GEÇTİ' if not critical else 'KALDI']
    write_text(out/'RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return (1 if critical else 0), out


def guide_alignment(root: Path) -> Tuple[int, Path]:
    out = out_dir(root, 'kilavuz_uyum')
    disp = parse_dispatch(root)
    docs = []
    for p in iter_files(root, {'.md'}):
        if 'UX_MINIMA' in p.name.upper() or 'KILAVUZ' in p.name.upper() or 'KULLANIM' in p.name.upper() or p.parts:
            docs.append(p)
    rows=[]
    for p in docs:
        txt = read_text(p)
        if not txt:
            continue
        for m in SERVICE_RE.finditer(txt):
            n=int(m.group(1))
            if n >= 700 or n in {270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,410,411,412,416,417,418,419}:
                rows.append({'servis':n,'durum':'DISPATCH_VAR' if n in disp else 'DOKUMANDA_VAR_DISPATCH_YOK','dosya':str(p.relative_to(root))})
    write_csv(out/'kilavuz_servis_uyum.csv', rows, ['servis','durum','dosya'])
    critical=[r for r in rows if r['durum']=='DOKUMANDA_VAR_DISPATCH_YOK']
    md=['# Stage-20 Kılavuz / Servis Uyumu','',f'- Dokümanda incelenen servis referansı: {len(rows)}',f'- Kritik dokümanda var dispatch yok: {len(critical)}',f'- Rapor: `{out}`','', '## Karar', 'GEÇTİ' if not critical else 'KALDI']
    write_text(out/'RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return (1 if critical else 0), out


def build_cache_manifest(root: Path, out: Path) -> None:
    rows=[]
    for p in iter_files(root, {'.bas','.fbs','.bi','.py','.bat','.ps1','.uxm','.expect','.md','.csv'}):
        rows.append({'dosya':str(p.relative_to(root)),'boyut':p.stat().st_size,'sha256':sha256(p)})
    write_csv(out/'build_cache_manifest.csv', rows, ['dosya','boyut','sha256'])


def exe_timing(root: Path, runs: int=5, timeout:int=20) -> Tuple[int, Path]:
    out = out_dir(root, 'performans')
    build_cache_manifest(root, out)
    exe = root/'build'/'exe'/'program.exe'
    timing=[]
    code=0
    if exe.exists():
        for i in range(1, runs+1):
            t0=time.time()
            try:
                p=subprocess.run(str(exe), cwd=str(exe.parent), capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
                rc=p.returncode; txt=((p.stdout or '')+(p.stderr or '')).replace('\r',' ').replace('\n',' ')[:200]
            except subprocess.TimeoutExpired:
                rc=124; txt='TIMEOUT'; code=1
            sec=time.time()-t0
            timing.append({'sira':i,'sure_saniye':f'{sec:.6f}','exit_code':rc,'cikti_ozet':txt})
            if rc != 0:
                code=1
    else:
        timing.append({'sira':0,'sure_saniye':'','exit_code':'EXE_YOK','cikti_ozet':'build/exe/program.exe bulunamadı; exe-only timing atlandı.'})
    write_csv(out/'exe_only_timing.csv', timing, ['sira','sure_saniye','exit_code','cikti_ozet'])
    md=['# Stage-20 Performans + Release Cleanup','',f'- Exe: `{exe}`',f'- Timing satırı: {len(timing)}',f'- Rapor: `{out}`','', 'Not: Exe yoksa performans kapısı bilgi raporu üretir; final testten sonra yeniden çalıştırılmalıdır.']
    write_text(out/'RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return code, out


def final_report(root: Path) -> Tuple[int, Path]:
    out = out_dir(root, 'final_rapor')
    report_dirs = sorted((root/'stage20_final_reports').glob('*/*/RAPOR.md')) if (root/'stage20_final_reports').exists() else []
    sections=['# UXM Stage-20 Final Release Kapısı Birleşik Raporu','',f'Zaman: {time.strftime("%Y-%m-%d %H:%M:%S")}','']
    for rp in report_dirs[-20:]:
        sections.append(f'## {rp.parent.name}')
        sections.append('')
        sections.append(read_text(rp))
        sections.append('')
    write_text(out/'STAGE20_FINAL_RAPOR.md','\n'.join(sections))
    print(f'Final rapor: {out / "STAGE20_FINAL_RAPOR.md"}')
    return 0, out


def run_tests(root: Path, no_build: bool=False, stop_on_fail: bool=False) -> int:
    bat = root/'hatali_test.bat'
    # Final stage testi için var olan Türkçe runner'ı kullan; yoksa sadece uyarı dön.
    test_dir = root/'uxm'/'tests'/'stage20_final'
    runner = root/'araclar'/'uxm_test_kos.py'
    if runner.exists():
        cmd=[sys.executable, str(runner), '--test-dir', str(test_dir), '--out-root', 'sonuclar_stage20_final']
        if no_build: cmd.append('-k')
        if stop_on_fail: cmd.append('-D')
        return subprocess.call(cmd, cwd=str(root))
    print('UYARI: araclar/uxm_test_kos.py bulunamadı; stage20_final UXM testleri çalıştırılmadı.')
    return 0


def all_gate(root: Path, no_build: bool=False, stop_on_fail: bool=False) -> int:
    codes=[]
    codes.append(run_tests(root,no_build,stop_on_fail))
    codes.append(placeholder_scan(root, include_docs=False, strict_reserved=False)[0])
    codes.append(service_alignment(root)[0])
    codes.append(guide_alignment(root)[0])
    codes.append(exe_timing(root, runs=3)[0])
    final_report(root)
    return 1 if any(c != 0 for c in codes) else 0


def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM Stage-20 Final Release Kapısı')
    ap.add_argument('komut', nargs='?', default='hepsi', choices=['hepsi','test','placeholder','servis','kilavuz','performans','rapor'], help='Çalıştırılacak görev')
    ap.add_argument('-p','--proje','--root', default='.', help='UXMv33 proje kökü')
    ap.add_argument('-k','--derleme-yok','--no-build', action='store_true', help='Testte derleme yapma')
    ap.add_argument('-D','--ilk-hatada-dur','--stop-on-fail', action='store_true', help='İlk hatada dur')
    ap.add_argument('-d','--dokuman-dahil','--include-docs', action='store_true', help='Placeholder taramasına dokümanları da dahil et')
    ap.add_argument('--reserved-hata','--strict-reserved', action='store_true', help='Reserved/Rezerve kelimelerini hata say')
    ap.add_argument('-n','--adet','--runs', type=int, default=5, help='Performans tekrar sayısı')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve()
    if args.komut=='hepsi': return all_gate(root,args.derleme_yok,args.ilk_hatada_dur)
    if args.komut=='test': return run_tests(root,args.derleme_yok,args.ilk_hatada_dur)
    if args.komut=='placeholder': return placeholder_scan(root,args.dokuman_dahil,args.reserved_hata)[0]
    if args.komut=='servis': return service_alignment(root)[0]
    if args.komut=='kilavuz': return guide_alignment(root)[0]
    if args.komut=='performans': return exe_timing(root,args.adet)[0]
    if args.komut=='rapor': return final_report(root)[0]
    return 2

if __name__ == '__main__':
    raise SystemExit(main())
