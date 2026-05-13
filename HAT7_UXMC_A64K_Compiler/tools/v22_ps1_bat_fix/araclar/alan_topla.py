#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse,csv,shutil
from pathlib import Path
from datetime import datetime
KEEP={"yardim","derleyici_derle","bellek_test","tum_test","hizli_tara","hatali_test","placeholder_tara","placeholder_kapi","stage20_release_kapi","rapor_goster","alan_topla","vscode_kur"}

def main():
    ap=argparse.ArgumentParser(description="UXM çalışma alanı toparlayıcı")
    ap.add_argument("--kok","--root",default=".")
    ap.add_argument("--uygula","--apply",action="store_true")
    ap.add_argument("--build-emekli","--retire-build",action="store_true")
    args=ap.parse_args()
    root=Path(args.kok).resolve(); rep=root/"toparlama_raporlari"/datetime.now().strftime("%Y%m%d_%H%M%S"); rep.mkdir(parents=True,exist_ok=True)
    moves=[]
    for p in root.glob("*.bat"):
        if p.stem not in KEEP and not p.stem.startswith("stage"):
            moves.append((p, root/"Emekliler"/"bat_eski"/p.name))
    if args.build_emekli and (root/"build").exists():
        moves.append((root/"build", root/"Emekliler"/"builds"/("build_"+datetime.now().strftime("%Y%m%d_%H%M%S"))))
    with (rep/"toparlama_manifest.csv").open("w",encoding="utf-8",newline="") as f:
        w=csv.writer(f); w.writerow(["kaynak","hedef"]); w.writerows([(str(a),str(b)) for a,b in moves])
    print(f"[ALAN_TOPLA] planlanan_tasima={len(moves)} rapor={rep}")
    if args.uygula:
        for src,dst in moves:
            dst.parent.mkdir(parents=True,exist_ok=True)
            if dst.exists():
                dst=dst.with_name(dst.stem+"_"+datetime.now().strftime("%H%M%S")+dst.suffix)
            shutil.move(str(src),str(dst))
        print("[ALAN_TOPLA] Tasima tamamlandi.")
    else:
        print("[ALAN_TOPLA] Dry-run. Gercek islem icin -u / --uygula kullan.")
if __name__=='__main__': main()
