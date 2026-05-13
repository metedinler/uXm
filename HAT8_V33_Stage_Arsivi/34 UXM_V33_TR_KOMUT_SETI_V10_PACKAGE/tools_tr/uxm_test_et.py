# -*- coding: utf-8 -*-
"""UXM Türkçe Beklenen/Gerçek Test Koşucusu V10.
Kısa seçenekler:
  -r/--kok               proje kökü
  -d/--dizin             test klasörü
  -m/--manifest          manifest CSV
  -c/--cikti             sonuç kök klasörü
  -k/--kurmadan          build_native çalıştırmadan devam et
  -D/--dur               ilk hatada dur
  -n/--adet              en çok N test
  -s/--sira              N. testten başla
  -a/--ara               adında metin geçenleri koş
  -z/--zaman             test timeout saniye
English aliases are also accepted: --root, --test-dir, --no-build, --stop-on-fail, --limit.
"""
from __future__ import annotations
import argparse, csv, hashlib, os, re, subprocess, sys, time, json
from pathlib import Path

try:
    csv.field_size_limit(sys.maxsize)
except Exception:
    pass

BUILD_NOISE_PREFIXES = (
    'ASM uretildi:', 'ASM üretildi:', '[V3.3', 'NASM:', 'nasm ', 'FreeBASIC runtime',
    'C:\\Users\\', '[UXM program derlendi', 'Runtime cache', 'Kullanim:', 'Kullanım:'
)
ERROR_TOKENS = ('error:', 'hata:', 'ld.exe:', 'cannot ', 'nosuch', 'Permission denied', 'file truncated')

def oku_metin(p: Path) -> str:
    return p.read_text(encoding='utf-8-sig', errors='replace')

def yaz_metin(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')

def kompakt(s: str) -> str:
    return re.sub(r'\s+', '', s.replace('\ufeff','')).strip()

def oku_expect(p: Path):
    text = oku_metin(p) if p.exists() else ''
    mode='compact'; exit_code=0; body=text
    if '---' in text:
        head, body = text.split('---', 1)
        for line in head.splitlines():
            low=line.strip().lower()
            if low.startswith('mode:'):
                mode=low.split(':',1)[1].strip() or 'compact'
            elif low.startswith('exit_code:'):
                try: exit_code=int(low.split(':',1)[1].strip())
                except Exception: exit_code=0
    return mode, exit_code, body.strip('\r\n')

def ayikla_program_ciktisi(raw: str) -> str:
    lines=[]
    for line in raw.splitlines():
        s=line.strip('\r')
        st=s.strip()
        if not st:
            continue
        low=st.lower()
        # Link/derleme hatası varsa actual olarak kalsın; runner build fail ayıracak.
        if any(tok in low for tok in ERROR_TOKENS):
            lines.append(st); continue
        if st.startswith(BUILD_NOISE_PREFIXES):
            continue
        if st.startswith('"') and ('fbc.exe' in st.lower() or 'nasm' in st.lower()):
            continue
        if st.startswith('[') and 'program derlendi' in low:
            continue
        lines.append(st)
    return '\n'.join(lines).strip()

def calistir(cmd: str, cwd: Path, timeout: int, env=None):
    t0=time.time()
    try:
        p=subprocess.run(cmd, cwd=str(cwd), shell=True, text=True, encoding='utf-8', errors='replace', capture_output=True, timeout=timeout, env=env)
        return p.returncode, p.stdout, p.stderr, time.time()-t0
    except subprocess.TimeoutExpired as e:
        out=(e.stdout or '') if isinstance(e.stdout,str) else ''
        err=(e.stderr or '') if isinstance(e.stderr,str) else ''
        return 124, out, err+'\nZAMAN_ASIMI', time.time()-t0

def testleri_bul(root: Path, test_dir: str|None, manifest: str|None):
    items=[]
    if manifest:
        mp=(root/manifest) if not Path(manifest).is_absolute() else Path(manifest)
        with mp.open('r',encoding='utf-8-sig',newline='') as f:
            for r in csv.DictReader(f):
                tp=r.get('test_path') or r.get('path') or r.get('test') or r.get('uxm')
                ep=r.get('expect_path') or r.get('expect')
                if not tp: continue
                t=(root/tp) if not Path(tp).is_absolute() else Path(tp)
                e=(root/ep) if ep and not Path(ep).is_absolute() else (Path(ep) if ep else t.with_suffix('.expect'))
                if t.exists() and e.exists(): items.append((t,e))
    else:
        td=root/(test_dir or 'uxm/tests/bellek_v10')
        for t in sorted(td.rglob('*.uxm')):
            e=t.with_suffix('.expect')
            if e.exists(): items.append((t,e))
    return items

def rel(root: Path, p: Path) -> str:
    try: return str(p.relative_to(root))
    except Exception: return str(p)

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM Türkçe test koşucusu V10', add_help=True)
    ap.add_argument('-r','--kok','--root', default='.', help='Proje kökü')
    ap.add_argument('-d','--dizin','--test-dir', default=None, help='Test klasörü')
    ap.add_argument('-m','--manifest', default=None, help='Test manifest CSV')
    ap.add_argument('-c','--cikti','--out-root', default='sonuclar_tr', help='Sonuç kök klasörü')
    ap.add_argument('-k','--kurmadan','--no-build', action='store_true', help='Ana derleyiciyi yeniden derleme')
    ap.add_argument('-D','--dur','--stop-on-fail', action='store_true', help='İlk hatada dur')
    ap.add_argument('-n','--adet','--limit', type=int, default=None, help='En çok kaç test')
    ap.add_argument('-s','--sira','--from-index', type=int, default=1, help='Kaçıncı testten başlanacak')
    ap.add_argument('-a','--ara','--name-contains', default='', help='Test adında aranacak metin')
    ap.add_argument('-z','--zaman','--timeout-test', type=int, default=90, help='Her test için saniye')
    ap.add_argument('--derleme-zamani','--timeout-build', type=int, default=120, help='Build timeout saniye')
    args=ap.parse_args(argv)
    root=Path(args.kok).resolve()
    tests=testleri_bul(root,args.dizin,args.manifest)
    if args.ara:
        tests=[x for x in tests if args.ara.lower() in rel(root,x[0]).lower()]
    if args.sira>1:
        tests=tests[args.sira-1:]
    if args.adet is not None:
        tests=tests[:args.adet]
    stamp=time.strftime('%Y%m%d_%H%M%S')
    out=root/args.cikti/f'kosu_{stamp}'
    (out/'loglar').mkdir(parents=True,exist_ok=True)
    (out/'program_ciktilari').mkdir(parents=True,exist_ok=True)
    (out/'uyusmazliklar').mkdir(parents=True,exist_ok=True)
    print(f'UXM Türkçe Test Koşucusu V10: test={len(tests)} sonuç={out}')
    build_code=0
    if not args.kurmadan:
        build_code,bo,be,bs=calistir('call build_native.bat', root, args.derleme_zamani)
        yaz_metin(out/'derleme_stdout.txt',bo); yaz_metin(out/'derleme_stderr.txt',be)
        print(f'[DERLEME] kod={build_code} süre={bs:.2f} sn')
        if build_code!=0:
            return build_code
    rows=[]; passed=mismatch=buildfail=skipped=0
    for i,(t,e) in enumerate(tests,1):
        mode, exp_code, exp_body=oku_expect(e)
        if mode in ('none','skip','atla'):
            skipped+=1; continue
        uid=f't{i:04d}_'+hashlib.sha1(str(t).encode('utf-8')).hexdigest()[:10]
        env=os.environ.copy(); env['UXM_BUILD_ID']=uid
        cmd=f'call build_one_native.bat "{rel(root,t)}" -x'
        code,so,se,sec=calistir(cmd,root,args.zaman,env=env)
        raw=(so or '') + (('\n'+se) if se else '')
        actual=ayikla_program_ciktisi(raw)
        expc=kompakt(exp_body); actc=kompakt(actual)
        ok=False; msg=''
        if code!=exp_code:
            status='BUILD_OR_RUN_FAIL'; buildfail+=1; msg=f'exit beklenen={exp_code} gerçek={code}'
        else:
            if mode=='exact': ok=(exp_body.strip()==actual.strip()); msg='exact'
            elif mode=='contains': ok=(expc in actc); msg='contains'
            else: ok=(expc==actc); msg='compact'
            if ok: status='BASARILI'; passed+=1
            else: status='UYUSMAZ'; mismatch+=1
        rawp=out/'loglar'/f'{i:04d}_{t.name}.raw.log'; yaz_metin(rawp,raw)
        progp=out/'program_ciktilari'/f'{i:04d}_{t.name}.program.txt'; yaz_metin(progp,actual)
        if status!='BASARILI':
            md=out/'uyusmazliklar'/f'{i:04d}_{t.stem}'; md.mkdir(parents=True,exist_ok=True)
            yaz_metin(md/'beklenen.txt',exp_body); yaz_metin(md/'gercek.txt',actual); yaz_metin(md/'ham.log',raw)
        print(f'[{i:04d}/{len(tests):04d}] {status} {rel(root,t)} ({sec:.2f} sn) kip={mode}')
        if status!='BASARILI':
            print(f'        {msg}')
            print(f'        beklenen: {expc[:160]}')
            print(f'        gerçek   : {actc[:160]}')
        rows.append({'sira':i,'durum':status,'kip':mode,'sure':f'{sec:.4f}','kod':code,'test':rel(root,t),'expect':rel(root,e),'beklenen_kompakt':expc,'gercek_kompakt':actc,'mesaj':msg,'ham_log':rel(root,rawp),'program_log':rel(root,progp)})
        if args.dur and status!='BASARILI': break
    csvp=out/'sonuclar.csv'
    with csvp.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,fieldnames=list(rows[0].keys()) if rows else ['sira','durum'])
        wr.writeheader(); wr.writerows(rows)
    summary={'toplam':len(tests),'basarili':passed,'uyusmaz':mismatch,'derleme_veya_calisma_hatasi':buildfail,'atlanan':skipped,'sonuc_klasoru':str(out)}
    yaz_metin(out/'ozet.json',json.dumps(summary,ensure_ascii=False,indent=2))
    yaz_metin(out/'RAPOR.md',f"# UXM Test Raporu\n\n- Toplam: {len(tests)}\n- Başarılı: {passed}\n- Uyuşmaz: {mismatch}\n- Derleme/çalışma hatası: {buildfail}\n- Atlanan: {skipped}\n\nCSV: `{csvp}`\n")
    print(f'BİTTİ: başarılı={passed}, uyuşmaz={mismatch}, derleme_veya_çalışma_hatası={buildfail}, atlanan={skipped}')
    print(f'RAPOR: {out}')
    return 0 if mismatch==0 and buildfail==0 else 1
if __name__=='__main__':
    raise SystemExit(main())
