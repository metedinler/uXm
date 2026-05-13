#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse, csv, json, os, re, subprocess, sys, time
from pathlib import Path
from datetime import datetime

META_PREFIX = "#source:embedded_EXPECT_OUTPUT"

def compact(s: str) -> str:
    return re.sub(r"\s+", "", s or "")

def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def parse_expect(uxm: Path):
    exp = uxm.with_suffix(".expect")
    raw = read_text(exp)
    mode = "compact"
    exit_code = 0
    body_lines = []
    in_body = False
    for line in raw.splitlines():
        s = line.strip()
        low = s.lower()
        if low.startswith("# mode:") or low.startswith("mode:"):
            mode = s.split(":",1)[1].strip().lower() or mode
            continue
        if low.startswith("# exit_code:") or low.startswith("exit_code:"):
            try: exit_code = int(s.split(":",1)[1].strip())
            except Exception: exit_code = 0
            continue
        if s == "---":
            in_body = True
            continue
        if s.startswith(META_PREFIX):
            tail = s[len(META_PREFIX):]
            if tail:
                body_lines.append(tail)
            continue
        if s.startswith("#source:"):
            continue
        if s.startswith("#") and not in_body:
            continue
        body_lines.append(line)
    body = "\n".join(body_lines).strip()
    return mode, exit_code, body, str(exp)

def extract_program_output(stdout: str, stderr: str) -> str:
    text = (stdout or "") + ("\n" + stderr if stderr else "")
    # Eski derleme gürültülerini olabildiğince ayıkla.
    lines = []
    skip_keys = ["Assembler messages", "ld.exe:", "gcc", "FreeBASIC", "[BUILD]", "Derleme", "compilation terminated"]
    for line in text.splitlines():
        st = line.strip()
        if not st:
            continue
        if any(k.lower() in st.lower() for k in skip_keys):
            continue
        if st.lower().startswith(("error:", "warning:", "hata:")):
            continue
        lines.append(line)
    return "\n".join(lines).strip() if lines else text.strip()

def run_cmd(cmd, cwd: Path, timeout: int):
    t0 = time.time()
    try:
        p = subprocess.run(cmd, cwd=str(cwd), shell=True, text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr, time.time()-t0
    except subprocess.TimeoutExpired as e:
        return 124, e.stdout or "", (e.stderr or "") + "\nZAMAN ASIMI", time.time()-t0

def discover_tests(root: Path, target: str):
    t = Path(target)
    if not t.is_absolute():
        t = root / t
    if t.suffix.lower() == ".csv":
        rows = []
        if not t.exists():
            return []
        with t.open("r", encoding="utf-8", errors="replace", newline="") as f:
            rdr = csv.DictReader(f)
            for r in rdr:
                p = r.get("test") or r.get("test_path") or r.get("dosya") or r.get("path") or ""
                if p:
                    pp = Path(p)
                    rows.append(pp if pp.is_absolute() else root/pp)
        return [p for p in rows if p.exists()]
    if t.is_dir():
        return sorted(t.rglob("*.uxm"))
    if t.is_file() and t.suffix.lower()==".uxm":
        return [t]
    return []

def main():
    ap = argparse.ArgumentParser(description="UXM Türkçe sağlam test koşucu")
    ap.add_argument("--kok", "--root", default=".")
    ap.add_argument("--test-klasoru", "--test-dir", required=True)
    ap.add_argument("--cikti", "--out", default="sonuclar")
    ap.add_argument("--derleme-yok", "--no-build", action="store_true")
    ap.add_argument("--ilk-hatada-dur", "--stop-on-fail", action="store_true")
    ap.add_argument("--adet", "--limit", type=int, default=0)
    ap.add_argument("--basla", "--from-index", type=int, default=1)
    ap.add_argument("--ara", "--name-contains", default="")
    ap.add_argument("--zaman", "--timeout-test", type=int, default=45)
    args = ap.parse_args()
    root = Path(args.kok).resolve()
    tests = discover_tests(root, args.test_klasoru)
    if args.ara:
        tests = [p for p in tests if args.ara.lower() in p.name.lower()]
    if args.basla > 1:
        tests = tests[args.basla-1:]
    if args.adet and args.adet > 0:
        tests = tests[:args.adet]
    run_dir = root / args.cikti / ("kosu_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
    (run_dir/"loglar").mkdir(parents=True, exist_ok=True)
    (run_dir/"program_ciktilari").mkdir(parents=True, exist_ok=True)
    print(f"UXM test koşusu başlıyor: test={len(tests)} rapor={run_dir}")
    if not args.derleme_yok and (root/"build_native.bat").exists():
        code,out,err,sec = run_cmd('cmd /c build_native.bat', root, 300)
        (run_dir/"derleme_stdout.txt").write_text(out, encoding="utf-8")
        (run_dir/"derleme_stderr.txt").write_text(err, encoding="utf-8")
        print(f"[DERLEME] code={code} sure={sec:.2f} sn")
        if code != 0:
            return code
    rows=[]; passed=mismatch=buildfail=skipped=0
    for i,p in enumerate(tests,1):
        mode, expected_code, expected, exp_path = parse_expect(p)
        rel = str(p.relative_to(root)) if str(p).startswith(str(root)) else str(p)
        cmd = f'cmd /c build_one_native.bat "{rel}"'
        code,out,err,sec = run_cmd(cmd, root, args.zaman)
        actual = extract_program_output(out, err)
        (run_dir/"loglar"/f"{i:04d}_{p.stem}.raw.log").write_text((out or "") + "\n" + (err or ""), encoding="utf-8")
        (run_dir/"program_ciktilari"/f"{i:04d}_{p.stem}.txt").write_text(actual, encoding="utf-8")
        ok = False
        status = ""
        if code != expected_code:
            status="DERLEME_CALISMA_HATASI"; buildfail += 1
        else:
            if mode == "exact": ok = (actual.strip() == expected.strip())
            elif mode == "contains": ok = (expected.strip() in actual)
            elif mode == "contains_compact": ok = (compact(expected) in compact(actual))
            else: ok = (compact(actual) == compact(expected))
            if ok: status="BASARILI"; passed += 1
            else: status="UYUSMAZ"; mismatch += 1
        rows.append({"sira":i,"durum":status,"test":rel,"mode":mode,"beklenen":expected,"gercek":actual,"sure":f"{sec:.2f}","expect":exp_path})
        print(f"[{i:04d}/{len(tests):04d}] {status} {rel} ({sec:.2f} sn) mode={mode}")
        if status != "BASARILI":
            print(f"        beklenen: {compact(expected)[:180]}")
            print(f"        gercek   : {compact(actual)[:180]}")
            if args.ilk_hatada_dur:
                break
    with (run_dir/"sonuclar.csv").open("w", encoding="utf-8", newline="") as f:
        w=csv.DictWriter(f, fieldnames=["sira","durum","test","mode","beklenen","gercek","sure","expect"])
        w.writeheader(); w.writerows(rows)
    summary={"toplam":len(tests),"basarili":passed,"uyusmaz":mismatch,"derleme_calisma_hatasi":buildfail,"atlanan":skipped}
    (run_dir/"ozet.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    rap=f"# UXM Test Raporu\n\n- Toplam: {len(tests)}\n- Başarılı: {passed}\n- Uyuşmaz: {mismatch}\n- Derleme/çalışma hatası: {buildfail}\n- Atlanan: {skipped}\n\nCSV: `{run_dir/'sonuclar.csv'}`\n"
    (run_dir/"RAPOR.md").write_text(rap, encoding="utf-8")
    print(f"BİTTİ: başarılı={passed}, uyuşmaz={mismatch}, derleme/çalışma hatası={buildfail}, atlanan={skipped}")
    print(f"RAPOR: {run_dir}")
    return 0 if mismatch==0 and buildfail==0 else 1
if __name__ == "__main__":
    raise SystemExit(main())
