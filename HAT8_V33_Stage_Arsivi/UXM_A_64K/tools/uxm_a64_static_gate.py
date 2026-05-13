#!/usr/bin/env python3
from pathlib import Path
import re, sys
root = Path(__file__).resolve().parents[1]
errors = []
warns = []
words = ["PLACEHOLDER", "TODO", "DUMMY", "STUB", "not implemented"]
for p in (root/"src").rglob("*"):
    if p.suffix.lower() not in [".bas", ".bi", ".ts", ".json"]:
        continue
    txt = p.read_text(errors="ignore")
    low = txt.lower()
    for w in words:
        if w.lower() in low:
            warns.append(f"{p.relative_to(root)} contains {w}")

native = root/"src/compiler/native/native_cli.bas"
txt = native.read_text(errors="ignore") if native.exists() else ""
if "Tape+Stack+Data tam 64 KB" not in txt:
    errors.append("native_cli.bas 64KB invariant mesajını taşımıyor")
comp = root/"src/compiler/native/uxm31_compiler_fb.bas"
txt = comp.read_text(errors="ignore") if comp.exists() else ""
if "Const UXM_TOTAL_BYTES As Long=65536" not in txt:
    errors.append("uxm31_compiler_fb.bas UXM_TOTAL_BYTES=65536 taşımıyor")
if "ADDR_SP_REL" not in txt or "AddMetaAddrInstr" not in txt:
    errors.append("Stage12 gelişmiş addressing/meta deklarasyonları eksik görünüyor")
meta = root/"src/runtime/runtime_meta_dispatch.bas"
if meta.exists() and re.search(r"(?im)^\s*End\s+Extern\s*$", meta.read_text(errors="ignore")):
    errors.append("runtime_meta_dispatch.bas içinde standalone End Extern kaldı")
interp = root/"src/interpreter/uxm_v20_interpreter.bas"
if interp.exists():
    itxt = interp.read_text(errors="ignore")
    if "16UL * 1024UL * 1024UL" in itxt:
        errors.append("interpreter hala 16MB sabitini taşıyor")
    if "interpreter_runtime_adapter_64k.bas" not in itxt:
        errors.append("interpreter 64K adaptere bağlı değil")

report = root/"reports/UXM_A64_STATIC_GATE.txt"
report.parent.mkdir(exist_ok=True)
report.write_text("ERRORS:\n" + "\n".join(errors) + "\n\nWARNINGS:\n" + "\n".join(warns), encoding="utf-8")
print(report.read_text(encoding="utf-8"))
if errors:
    sys.exit(1)
sys.exit(0)
