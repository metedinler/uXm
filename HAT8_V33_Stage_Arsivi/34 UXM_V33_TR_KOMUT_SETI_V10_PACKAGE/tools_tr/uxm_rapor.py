# -*- coding: utf-8 -*-
from __future__ import annotations
import json, csv, argparse
from pathlib import Path
def latest(root:Path):
    files=list(root.glob('**/ozet.json'))+list(root.glob('**/summary*.json'))
    files=[p for p in files if any(x in str(p).lower() for x in ['sonuclar','expected','fast','hizli'])]
    return max(files,key=lambda p:p.stat().st_mtime) if files else None
def main():
    ap=argparse.ArgumentParser(description='UXM Türkçe son rapor okuyucu')
    ap.add_argument('-r','--kok','--root',default='.')
    a=ap.parse_args(); root=Path(a.kok).resolve(); p=latest(root)
    if not p: print('Rapor bulunamadı.'); return 1
    print('Son rapor:',p)
    try: print(json.dumps(json.loads(p.read_text(encoding='utf-8-sig')),ensure_ascii=False,indent=2))
    except Exception: print(p.read_text(encoding='utf-8-sig',errors='replace')[:2000])
    return 0
if __name__=='__main__': raise SystemExit(main())
