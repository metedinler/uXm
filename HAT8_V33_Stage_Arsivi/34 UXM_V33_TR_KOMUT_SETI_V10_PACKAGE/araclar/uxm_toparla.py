# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, shutil, time
from pathlib import Path
KOK_BAT={
 'yardim.bat','derle.bat','bellek.bat','hizli.bat','hata.bat','tum.bat','topla.bat','vscode_kur.bat','rapor.bat',
 'y.bat','d.bat','b.bat','h.bat','e.bat','t.bat','k.bat','v.bat','r.bat','build_native.bat','build_one_native.bat'
}
KEEP_DIR={'uxm','araclar','tools','tools_tr','vscode','Emekliler','sonuclar_tr','hizli_sonuclar','build'}
def plan(root:Path, retire_build=False):
    stamp=time.strftime('%Y%m%d_%H%M%S'); moves=[]
    for p in root.iterdir():
        n=p.name
        if p.is_file():
            low=n.lower()
            if low.endswith('.bat') and n not in KOK_BAT: dest=root/'Emekliler'/'bat_eski'/stamp/n
            elif low.endswith('.py') and p.parent==root: dest=root/'Emekliler'/'python_eski'/stamp/n
            elif low.endswith(('.zip','.diff')): dest=root/'Emekliler'/'paketler'/stamp/n
            elif low.endswith(('.csv','.txt','.log','.json','.md')) and not low.startswith('readme'): dest=root/'Emekliler'/'raporlar'/stamp/n
            else: continue
            moves.append((p,dest))
        elif p.is_dir():
            if n in KEEP_DIR: continue
            if n.lower().startswith('expected_results') or n.lower().startswith('fast_results') or n.lower().startswith('workspace_clean_reports') or n.lower().startswith('mismatch_'):
                moves.append((p,root/'Emekliler'/'sonuc_klasorleri'/stamp/n))
            elif retire_build and n.lower().startswith('build'):
                moves.append((p,root/'Emekliler'/'builds'/stamp/n))
    return stamp,moves
def main():
    ap=argparse.ArgumentParser(description='UXM Türkçe çalışma alanı toparlayıcı')
    ap.add_argument('-r','--kok','--root',default='.')
    ap.add_argument('-u','--uygula','--apply',action='store_true')
    ap.add_argument('-b','--build-emekli','--retire-build',action='store_true')
    a=ap.parse_args(); root=Path(a.kok).resolve(); stamp,moves=plan(root,a.build_emekli)
    rep=root/'toparlama_raporlari'/stamp; rep.mkdir(parents=True,exist_ok=True)
    with (rep/'toparlama_manifest.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.writer(f); wr.writerow(['kaynak','hedef'])
        for s,d in moves: wr.writerow([str(s),str(d)])
    if a.uygula:
        for s,d in moves:
            d.parent.mkdir(parents=True,exist_ok=True)
            if d.exists(): d=d.with_name(d.stem+'_2'+d.suffix)
            shutil.move(str(s),str(d))
        print(f'[TOPARLA] Uygulandı. Taşınan: {len(moves)} Rapor: {rep}')
    else:
        print(f'[TOPARLA] Önizleme. Planlanan taşıma: {len(moves)} Rapor: {rep}')
        print('[TOPARLA] Gerçek işlem için: topla.bat -u')
if __name__=='__main__': raise SystemExit(main())
