# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, sys, time, json, re
from pathlib import Path
try: csv.field_size_limit(sys.maxsize)
except Exception: pass
BAD={'UYUSMAZ','BUILD_FAIL','BUILD_OR_RUN_FAIL','BUILD_OR_RUNTIME_ERROR'}
def compact_key(path:str)->str:
    p=path.replace('\\','/').lower()
    p=re.sub(r'^.*?uxm/tests/','uxm/tests/',p)
    p=re.sub(r'^\d+__s\d+_[^/]+__','',p)
    p=re.sub(r'__[0-9a-f]{10}(?=\.uxm$)','',p)
    return p
def find_csv(root:Path, src:str|None):
    if src:
        p=root/src
        if p.exists(): return p
        raise FileNotFoundError(f'CSV bulunamadı: {p}')
    pats=['expected_results_v*/**/expected_results*.csv','all_expected_results/**/*.csv','fast_results/runs/**/sonuclar.csv','sonuclar_tr/**/sonuclar.csv']
    found=[]
    for pat in pats: found += list(root.glob(pat))
    found=[p for p in found if p.is_file()]
    if not found: raise FileNotFoundError('expected_results/sonuclar CSV bulunamadı')
    return max(found, key=lambda p:p.stat().st_mtime)
def main():
    ap=argparse.ArgumentParser(description='UXM Türkçe hızlı hata anahtarı tarayıcı V10')
    ap.add_argument('-r','--kok','--root',default='.')
    ap.add_argument('-g','--girdi','--source',default=None,help='Kaynak CSV')
    ap.add_argument('-c','--cikti','--out',default='hizli_sonuclar/son')
    ap.add_argument('-S','--sinif',default='',help='Sadece durum/sınıf filtresi')
    a=ap.parse_args(); root=Path(a.kok).resolve(); out=root/a.cikti; out.mkdir(parents=True,exist_ok=True)
    src=find_csv(root,a.girdi)
    rows=[]
    with src.open('r',encoding='utf-8-sig',newline='') as f:
        for r in csv.DictReader(f):
            durum=(r.get('status') or r.get('durum') or '').upper()
            test=r.get('test_path') or r.get('test') or ''
            if not test: continue
            if durum in BAD or durum not in ('BASARILI','PASSED','OK',''):
                if a.sinif and a.sinif.lower() not in (durum+' '+str(r)).lower(): continue
                r['semantic_key']=compact_key(test); r['durum_norm']=durum; rows.append(r)
    unique={}
    for r in rows: unique.setdefault(r['semantic_key'],r)
    fields=sorted(set().union(*(r.keys() for r in rows))) if rows else ['test_path','semantic_key']
    for name,data in [('hatali_tum_manifest.csv',rows),('hatali_tekil_manifest.csv',list(unique.values()))]:
        with (out/name).open('w',encoding='utf-8-sig',newline='') as f:
            wr=csv.DictWriter(f,fieldnames=fields); wr.writeheader(); wr.writerows(data)
    summary={'kaynak':str(src),'hatali_satir':len(rows),'tekil_hata_anahtari':len(unique),'cikti':str(out)}
    (out/'ozet.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
    (out/'RAPOR.md').write_text(f"# Hızlı Hata Anahtar Raporu\n\nKaynak: `{src}`\n\n- Hatalı satır: {len(rows)}\n- Tekil hata anahtarı: {len(unique)}\n\n",encoding='utf-8')
    print(f"[HIZLI TARA] kaynak={src} hatalı_satır={len(rows)} tekil={len(unique)}")
    print(f"[HIZLI TARA] manifest={out/'hatali_tekil_manifest.csv'}")
    return 0
if __name__=='__main__': raise SystemExit(main())
