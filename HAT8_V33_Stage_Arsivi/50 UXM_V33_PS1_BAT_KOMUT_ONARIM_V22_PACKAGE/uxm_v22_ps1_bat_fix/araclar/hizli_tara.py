#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse,csv,json
from pathlib import Path
from datetime import datetime

def latest_csv(root: Path):
    files = list(root.glob("sonuclar_*/*/sonuclar.csv")) + list(root.glob("expected_results*/*/*.csv"))
    files = [p for p in files if p.is_file()]
    if not files:
        raise FileNotFoundError("sonuclar.csv bulunamadi")
    return max(files, key=lambda p:p.stat().st_mtime)

def main():
    ap=argparse.ArgumentParser(description="UXM hızlı hata tarama")
    ap.add_argument("--kok","--root",default=".")
    ap.add_argument("--kaynak","--source",default="")
    args=ap.parse_args()
    root=Path(args.kok).resolve()
    src=Path(args.kaynak).resolve() if args.kaynak else latest_csv(root)
    out=root/"hizli_sonuclar"/"son"
    out.mkdir(parents=True,exist_ok=True)
    rows=[]
    with src.open("r",encoding="utf-8",errors="replace",newline="") as f:
        rdr=csv.DictReader(f)
        for r in rdr:
            durum=(r.get("durum") or r.get("status") or "").upper()
            if durum and durum not in ("BASARILI","PASSED","PASS"):
                rows.append(r)
    unique=[]; seen=set()
    for r in rows:
        p=r.get("test") or r.get("path") or r.get("dosya") or ""
        key=Path(p).name if p else json.dumps(r,ensure_ascii=False)
        if key not in seen:
            seen.add(key); unique.append({"test":p,"anahtar":key,"durum":r.get("durum") or r.get("status") or ""})
    for name,data in [("hatali_tekil_manifest.csv",unique),("hatali_tum_kopyalar_manifest.csv",[{"test":r.get("test") or r.get("path") or r.get("dosya") or "","durum":r.get("durum") or r.get("status") or ""} for r in rows])]:
        with (out/name).open("w",encoding="utf-8",newline="") as f:
            w=csv.DictWriter(f,fieldnames=list(data[0].keys()) if data else ["test","durum"])
            w.writeheader(); w.writerows(data)
    (out/"ozet.json").write_text(json.dumps({"kaynak":str(src),"toplam_hatali":len(rows),"tekil_hatali":len(unique)},ensure_ascii=False,indent=2),encoding="utf-8")
    (out/"HIZLI_RAPOR.md").write_text(f"# Hızlı Tarama\n\nKaynak: `{src}`\n\nHatalı satır: {len(rows)}\n\nTekil hatalı anahtar: {len(unique)}\n",encoding="utf-8")
    print(f"[HIZLI_TARA] kaynak={src} hatalı_satır={len(rows)} tekil_hatalı_anahtar={len(unique)}")
    print(f"[HIZLI_TARA] manifest={out/'hatali_tekil_manifest.csv'}")
if __name__=='__main__': main()
