#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse,csv,re,sys
from pathlib import Path

PATTERNS=["placeholder","dummy","stub","todo","fixme","not implemented","reserved","planlandi","planlandı","bos islev","boş işlev","fake"]
EXCLUDE_DIRS={".git","build","Emekliler","sonuclar_bellek","sonuclar_tum","sonuclar_hatali","hizli_sonuclar","placeholder_raporu"}
EXTS={".bas",".bi",".fbs",".py",".ps1",".bat",".md",".json",".csv",".uxm",".expect"}

def main():
    ap=argparse.ArgumentParser(description="UXM placeholder/TODO/dummy taraması")
    ap.add_argument("--kok","--root",default=".")
    ap.add_argument("--cikti","--out",default="placeholder_raporu")
    ap.add_argument("--hata-ver","--fail",action="store_true")
    args=ap.parse_args()
    root=Path(args.kok).resolve(); out=root/args.cikti; out.mkdir(parents=True,exist_ok=True)
    findings=[]
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix.lower() not in EXTS: continue
        if any(part in EXCLUDE_DIRS for part in p.parts): continue
        try: txt=p.read_text(encoding="utf-8",errors="replace")
        except Exception: continue
        for no,line in enumerate(txt.splitlines(),1):
            low=line.lower()
            for pat in PATTERNS:
                if pat in low:
                    findings.append({"dosya":str(p.relative_to(root)),"satir":no,"anahtar":pat,"icerik":line.strip()[:240]})
                    break
    with (out/"placeholder_bulgular.csv").open("w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,fieldnames=["dosya","satir","anahtar","icerik"]); w.writeheader(); w.writerows(findings)
    md=["# Placeholder/TODO/Dummy Raporu","",f"Bulgu sayisi: {len(findings)}",""]
    for r in findings[:200]: md.append(f"- `{r['dosya']}:{r['satir']}` **{r['anahtar']}** — {r['icerik']}")
    (out/"PLACEHOLDER_RAPORU.md").write_text("\n".join(md),encoding="utf-8")
    print(f"[PLACEHOLDER_TARA] bulgu={len(findings)} rapor={out/'PLACEHOLDER_RAPORU.md'}")
    if args.hata_ver and findings: return 1
    return 0
if __name__=='__main__': raise SystemExit(main())
