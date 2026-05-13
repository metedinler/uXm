#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM-A-64K kurucu
-----------------
Bu program, 'uçma' klasöründe kendi adlarıyla açılmış UXM zip klasörlerinden
64 KB memory hattına uygun en iyi kaynak ağacını seçici olarak kurar.

Temel fikir:
- 52 UXM_V33_V20_SRC_KLASORU.zip => temiz src mimarisi
- 13 UXM_V33_STAGE12_tensor_advanced2_package.zip => gelişmiş native compiler split dosyaları
- 52 V20 runtime/services => V18/V19 gerçek runtime servis birleşimi
- 39 V15 vscode => kurulabilir VSCode artifact
- 24 final expected tests, 47/51 release gate, 50 V22 komut onarımı => araç/test hattı

Program körlemesine unzip yapmaz. Açılmış klasörleri arar, seçici kopyalar ve kritik kod patchlerini uygular.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable, Optional

UTF8 = "utf-8"

NATIVE_STAGE12_FILES = [
    "native_lexer_parser.bas",
    "native_addressing.bas",
    "native_meta_parse.bas",
    "native_validation.bas",
    "native_asm_emit.bas",
    "native_main.bas",
]

VSCODE_V15_FILES = [
    "package.json",
    "extension.js",
    "language-configuration.json",
    "snippets/uxm.json",
    "syntaxes/uxm.tmLanguage.json",
]

PLACEHOLDER_WORDS = [
    "TODO", "TO DO", "DUMMY", "PLACEHOLDER", "STUB", "SKELETON",
    "NO-OP", "NOOP", "not implemented", "fake",
]

@dataclass
class Action:
    layer: str
    action: str
    source: str
    target: str
    status: str
    note: str = ""
    sha256: str = ""

class BuildError(RuntimeError):
    pass

class UXMA64KBuilder:
    def __init__(self, root: Path, out: Path, force: bool = False, dry_run: bool = False, verbose: bool = True):
        self.root = root.resolve()
        self.out = out.resolve()
        self.force = force
        self.dry_run = dry_run
        self.verbose = verbose
        self.actions: list[Action] = []
        self.packages: dict[str, Path] = {}

    def log(self, msg: str) -> None:
        if self.verbose:
            print(msg)

    def run(self) -> None:
        self.validate_root()
        self.locate_packages()
        self.prepare_output()
        self.copy_v20_src_base()
        self.overlay_stage12_native()
        self.patch_native_compiler_header()
        self.patch_native_cli_64k()
        self.patch_runtime_meta_dispatch()
        self.patch_interpreter_64k_adapter()
        self.copy_vscode_artifacts()
        self.copy_tests_and_tools()
        self.create_gate_scripts()
        self.write_reports()
        self.log(f"\nOK: UXM-A-64K çalışma ağacı hazır: {self.out}")

    def validate_root(self) -> None:
        if not self.root.exists() or not self.root.is_dir():
            raise BuildError(f"Uçma/root klasörü bulunamadı: {self.root}")

    def locate_packages(self) -> None:
        children = [p for p in self.root.iterdir() if p.is_dir()]
        if not children:
            raise BuildError(f"Root içinde açılmış zip klasörü yok: {self.root}")

        def find_pkg(prefix: str, required_token: str | None = None) -> Optional[Path]:
            matches = []
            for p in children:
                n = p.name.lower()
                if n.startswith(prefix.lower() + " ") or n.startswith(prefix.lower() + "_") or n == prefix.lower():
                    if required_token is None or required_token.lower() in n:
                        matches.append(p)
            if matches:
                return sorted(matches, key=lambda x: len(x.name))[0]
            # fallback by token anywhere
            for p in children:
                n = p.name.lower()
                if n.startswith(prefix.lower()) and (required_token is None or required_token.lower() in n):
                    matches.append(p)
            return sorted(matches, key=lambda x: len(x.name))[0] if matches else None

        required = {
            "stage12": ("13", "stage12"),
            "v20src": ("52", "v20_src"),
        }
        optional = {
            "v15tools": ("39", "v15"),
            "final_tests": ("24", "final_expected"),
            "release_gate": ("47", "release_gate"),
            "release_gate_dup": ("51", "release_gate"),
            "v22_fix": ("50", "v22"),
        }

        for key, (prefix, token) in required.items():
            p = find_pkg(prefix, token)
            if p is None:
                raise BuildError(f"Zorunlu paket bulunamadı: {prefix} / {token}")
            self.packages[key] = p

        for key, (prefix, token) in optional.items():
            p = find_pkg(prefix, token)
            if p is not None:
                self.packages[key] = p

        if "release_gate" not in self.packages and "release_gate_dup" in self.packages:
            self.packages["release_gate"] = self.packages["release_gate_dup"]

        self.log("Bulunan paketler:")
        for k, v in self.packages.items():
            self.log(f"  {k:16s} -> {v.name}")

    def prepare_output(self) -> None:
        if self.out.exists():
            if not self.force:
                raise BuildError(f"Çıkış klasörü zaten var: {self.out}  (--force kullan veya klasörü sil)")
            if not self.dry_run:
                shutil.rmtree(self.out)
        if not self.dry_run:
            (self.out / "src").mkdir(parents=True, exist_ok=True)
            (self.out / "reports").mkdir(parents=True, exist_ok=True)
            (self.out / "tools").mkdir(parents=True, exist_ok=True)
            (self.out / "tests").mkdir(parents=True, exist_ok=True)
            (self.out / "build").mkdir(parents=True, exist_ok=True)

    # ---------- Path helpers ----------
    def find_dir_named(self, package: Path, rel_suffix: str) -> Path:
        suffix = Path(rel_suffix)
        # direct
        direct = package / suffix
        if direct.exists() and direct.is_dir():
            return direct
        candidates = []
        parts = suffix.parts
        for p in package.rglob(parts[-1]):
            if p.is_dir() and tuple(p.parts[-len(parts):]) == parts:
                candidates.append(p)
        if not candidates:
            raise BuildError(f"Dizin bulunamadı: {package.name} :: {rel_suffix}")
        return sorted(candidates, key=lambda x: len(str(x)))[0]

    def find_file_named(self, package: Path, rel_suffix: str) -> Path:
        suffix = Path(rel_suffix)
        direct = package / suffix
        if direct.exists() and direct.is_file():
            return direct
        candidates = []
        parts = suffix.parts
        for p in package.rglob(parts[-1]):
            if p.is_file() and tuple(p.parts[-len(parts):]) == parts:
                candidates.append(p)
        if not candidates:
            raise BuildError(f"Dosya bulunamadı: {package.name} :: {rel_suffix}")
        return sorted(candidates, key=lambda x: len(str(x)))[0]

    def sha(self, p: Path) -> str:
        h = hashlib.sha256()
        with p.open("rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()

    def copy_tree(self, src: Path, dst: Path, layer: str, note: str = "") -> None:
        self.log(f"COPY TREE [{layer}] {src} -> {dst}")
        if not self.dry_run:
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        self.actions.append(Action(layer, "COPY_TREE", str(src), str(dst), "OK", note))

    def copy_file(self, src: Path, dst: Path, layer: str, note: str = "") -> None:
        self.log(f"COPY FILE [{layer}] {src.name} -> {dst}")
        if not self.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        self.actions.append(Action(layer, "COPY_FILE", str(src), str(dst), "OK", note, self.sha(src) if src.exists() else ""))

    def write_text(self, path: Path, text: str, layer: str, note: str = "") -> None:
        self.log(f"WRITE [{layer}] {path}")
        if not self.dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding=UTF8, newline="\n")
        sha = hashlib.sha256(text.encode(UTF8)).hexdigest()
        self.actions.append(Action(layer, "WRITE_TEXT", "<generated>", str(path), "OK", note, sha))

    def patch_file(self, path: Path, patch_fn, layer: str, note: str = "") -> None:
        old = path.read_text(encoding=UTF8, errors="ignore")
        new = patch_fn(old)
        if new == old:
            self.actions.append(Action(layer, "PATCH", str(path), str(path), "NO_CHANGE", note, self.sha(path)))
            return
        if not self.dry_run:
            bak = path.with_suffix(path.suffix + ".uxma.bak")
            if not bak.exists():
                bak.write_text(old, encoding=UTF8, newline="\n")
            path.write_text(new, encoding=UTF8, newline="\n")
        sha = hashlib.sha256(new.encode(UTF8)).hexdigest()
        self.actions.append(Action(layer, "PATCH", str(path), str(path), "OK", note, sha))

    # ---------- Build steps ----------
    def copy_v20_src_base(self) -> None:
        v20_src = self.find_dir_named(self.packages["v20src"], "src")
        self.copy_tree(v20_src, self.out / "src", "base", "V20 temiz src mimarisi temel alındı.")

    def overlay_stage12_native(self) -> None:
        native_dir = self.find_dir_named(self.packages["stage12"], "uxm/core/compiler/native")
        target_dir = self.out / "src/compiler/native"
        for fname in NATIVE_STAGE12_FILES:
            self.copy_file(native_dir / fname, target_dir / fname, "compiler/native", "Stage12 gelişmiş native compiler split dosyası.")
        # Stage12 source for patched files
        self.copy_file(native_dir / "uxm31_compiler_fb.bas", target_dir / "uxm31_compiler_fb.bas", "compiler/native", "Patch öncesi Stage12 ana compiler header dosyası.")
        self.copy_file(native_dir / "native_cli.bas", target_dir / "native_cli.bas", "compiler/native", "Patch öncesi Stage12 CLI/memory dosyası.")

    def patch_native_compiler_header(self) -> None:
        p = self.out / "src/compiler/native/uxm31_compiler_fb.bas"

        def patch(txt: str) -> str:
            txt = re.sub(r'Const\s+UXM_VERSION\s+As\s+String\s*=.*',
                         'Const UXM_VERSION As String="3.3-UXM-A-64K-stage12-v20-merged"', txt)
            old_block = re.compile(
                r'Const\s+UXM_DEFAULT_TAPE_KB\s+As\s+Long\s*=.*?'
                r'Const\s+UXM_MEMORY_POLICY_TOTAL\s+As\s+Long\s*=\s*1\s*',
                re.S | re.I,
            )
            new_block = """Const UXM_TOTAL_BYTES As Long=65536
Const UXM_TOTAL_KB As Long=64
Const UXM_DEFAULT_TAPE_KB As Long=32
Const UXM_DEFAULT_STACK_KB As Long=8
Const UXM_DEFAULT_DATA_KB As Long=24
Const UXM_DEFAULT_QUEUE_KB As Long=4
Const UXM_MAX_TAPE_KB As Long=64
Const UXM_MAX_STACK_KB As Long=64
Const UXM_MAX_DATA_KB As Long=64
Const UXM_MAX_QUEUE_KB As Long=256
Const UXM_MAX_TOTAL_KB As Long=64
Const UXM_MEMORY_POLICY_BOUNDED As Long=0
Const UXM_MEMORY_POLICY_TOTAL As Long=1
"""
            txt2, n = old_block.subn(new_block, txt, count=1)
            if n == 0 and "Const UXM_TOTAL_BYTES As Long=65536" not in txt:
                txt2 = txt.replace('Const MAX_LABELS As Long=200000', 'Const MAX_LABELS As Long=200000\n' + new_block, 1)
            marker = "' UXM-A-64K MERGE NOTE:"
            if marker not in txt2:
                txt2 = txt2.replace('#Include Once "../extensions/arge_parse_math_additions.bas"',
                    "' UXM-A-64K MERGE NOTE: Stage12 native compiler declarations preserved; memory defaults locked to 64 KB.\n#Include Once \"../extensions/arge_parse_math_additions.bas\"", 1)
            return txt2

        self.patch_file(p, patch, "compiler/native", "uxm31_compiler_fb.bas 64KB sabitleri + Stage12 gelişmiş deklarasyonları.")

    def patch_native_cli_64k(self) -> None:
        p = self.out / "src/compiler/native/native_cli.bas"

        new_apply = '''Sub ApplyMemoryModel()
    ' UXM-A-64K: ana tape+stack+data memory kesin olarak 64 KB kalır.
    ' Queue/FIFO fiziksel deposu runtime tarafında ayrı değerlendirilir; UXM_TOTAL_BYTES içine katılmaz.
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    QueueBytes=QueueKB*1024

    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If

    If TapeKB<=0 Or StackKB<=0 Or DataKB<=0 Or QueueKB<=0 Then
        HadError=1
        ErrMsg="HATA: #memory alanlari KB cinsinden 1 veya daha buyuk olmali. Tape="+Str(TapeKB)+" Stack="+Str(StackKB)+" Data="+Str(DataKB)+" Queue="+Str(QueueKB)
        Exit Sub
    End If

    MemoryTotalLimitKB=UXM_TOTAL_KB

    If TapeKB>UXM_MAX_TAPE_KB Or StackKB>UXM_MAX_STACK_KB Or DataKB>UXM_MAX_DATA_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A-64K hattinda tape/stack/data alanlari ayri ayri 64 KB ustune cikamaz. Tape="+Str(TapeKB)+" Stack="+Str(StackKB)+" Data="+Str(DataKB)
        Exit Sub
    End If

    If QueueKB>UXM_MAX_QUEUE_KB Then
        HadError=1
        ErrMsg="HATA: queue/fifo fiziksel ust siniri " + Str(UXM_MAX_QUEUE_KB) + " KB. Verilen="+Str(QueueKB)+" KB."
        Exit Sub
    End If

    If TapeKB+StackKB+DataKB<>UXM_TOTAL_KB Then
        HadError=1
        ErrMsg="HATA: UXM-A-64K hattinda Tape+Stack+Data tam 64 KB olmali. Verilen toplam="+Str(TapeKB+StackKB+DataKB)+" KB. Queue/FIFO bu toplama dahil degildir."
        Exit Sub
    End If

    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize()
    StackCells=StackBytes\CellSize()
    DataCells=DataBytes\CellSize()
    QueueCells=QueueBytes\CellSize()
    If QueueCells<1 Then QueueCells=1
End Sub'''

        def patch(txt: str) -> str:
            # Replace whole ApplyMemoryModel body up to next Sub ReadFileToSrc
            txt = re.sub(r'Sub\s+ApplyMemoryModel\(\).*?\nEnd Sub\s*\n\s*Sub\s+ReadFileToSrc',
                         lambda _m: new_apply + "\n\nSub ReadFileToSrc", txt, flags=re.S | re.I, count=1)
            # total/max pragma checks: reject >64 instead of silently switching to 16MB line.
            txt = re.sub(
                r'v=GetPragmaValue\(low,"total"\)\s*\n\s*If\s+v<>""\s+Then\s+MemoryTotalLimitKB=ParseSizeKB\(v,MemoryTotalLimitKB\)\s*\n\s*v=GetPragmaValue\(low,"max"\)\s*\n\s*If\s+v<>""\s+Then\s+MemoryTotalLimitKB=ParseSizeKB\(v,MemoryTotalLimitKB\)',
                '''v=GetPragmaValue(low,"total")
                If v<>"" Then
                    MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)
                    If MemoryTotalLimitKB<>UXM_TOTAL_KB Then
                        HadError=1
                        ErrMsg="HATA: UXM-A-64K hattinda #memory total/max sadece 64KB olabilir. Verilen="+Str(MemoryTotalLimitKB)+" KB"
                        Exit Sub
                    End If
                End If
                v=GetPragmaValue(low,"max")
                If v<>"" Then
                    MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)
                    If MemoryTotalLimitKB<>UXM_TOTAL_KB Then
                        HadError=1
                        ErrMsg="HATA: UXM-A-64K hattinda #memory total/max sadece 64KB olabilir. Verilen="+Str(MemoryTotalLimitKB)+" KB"
                        Exit Sub
                    End If
                End If''',
                txt,
                flags=re.I,
                count=1,
            )
            if "UXM-A-64K" not in txt.splitlines()[0:20].__str__():
                txt = txt.replace("' Auto-split by V3 modularization", "' Auto-split by V3 modularization\n' UXM-A-64K patched native_cli: 64 KB ana memory invariant korunur.", 1)
            return txt

        self.patch_file(p, patch, "compiler/native", "native_cli.bas 64KB Tape+Stack+Data invariantı.")

    def patch_runtime_meta_dispatch(self) -> None:
        p = self.out / "src/runtime/runtime_meta_dispatch.bas"
        if not p.exists():
            self.actions.append(Action("runtime", "PATCH", str(p), str(p), "MISSING", "runtime_meta_dispatch.bas bulunamadı."))
            return

        def patch(txt: str) -> str:
            lines = []
            removed = 0
            for line in txt.splitlines():
                if line.strip().lower() == "end extern":
                    removed += 1
                    continue
                lines.append(line)
            out = "\n".join(lines) + "\n"
            if removed and "UXM-A-64K" not in out:
                out = "' UXM-A-64K patch: standalone End Extern satiri kaldirildi; dosya runtime full icinde include edilir.\n" + out
            return out

        self.patch_file(p, patch, "runtime", "runtime_meta_dispatch.bas standalone End Extern temizliği.")

    def patch_interpreter_64k_adapter(self) -> None:
        interp = self.out / "src/interpreter/uxm_v20_interpreter.bas"
        runtime_full = self.out / "src/runtime/uxm31_runtime_fb_full.bas"
        runtime_memory = self.out / "src/runtime/runtime_memory.bas"
        if not interp.exists() or not runtime_full.exists() or not runtime_memory.exists():
            self.actions.append(Action("interpreter", "PATCH", str(interp), str(interp), "MISSING", "Interpreter veya runtime dosyaları eksik."))
            return

        # 1) runtime_memory adapter: @ux_mem => @ux_mem(0)
        mem_txt = runtime_memory.read_text(encoding=UTF8, errors="ignore")
        mem_txt = mem_txt.replace("Return @ux_mem+", "Return @ux_mem(0)+")
        mem_txt = re.sub(r'Return\s+@ux_mem\s*$', 'Return @ux_mem(0)', mem_txt, flags=re.I | re.M)
        mem_txt = "' UXM-A-64K interpreter adapter memory layer: array ux_mem(0) pointer kullanir.\n" + mem_txt
        self.write_text(self.out / "src/interpreter/interpreter_runtime_memory_64k.bas", mem_txt, "interpreter", "runtime_memory adapteri üretildi.")

        # 2) runtime full adapter: remove Extern block and rewrite includes relative to interpreter folder.
        rf = runtime_full.read_text(encoding=UTF8, errors="ignore")
        rf = re.sub(r'^#Lang\s+"fb"\s*\n', '', rf, flags=re.I)
        rf = re.sub(r'Extern\s+"C".*?End\s+Extern\s*\n', '', rf, flags=re.S | re.I)
        rf = rf.replace('#Include Once "runtime_memory.bas"', '#Include Once "interpreter_runtime_memory_64k.bas"')
        rf = re.sub(r'#Include Once "(runtime_[^"]+\.bas)"', r'#Include Once "../runtime/\1"', rf)
        rf = re.sub(r'#Include Once "services/([^"]+)"', r'#Include Once "../runtime/services/\1"', rf)
        rf = re.sub(r'#Include Once "hooks/([^"]+)"', r'#Include Once "../runtime/hooks/\1"', rf)
        prepend = '''' UXM-A-64K interpreter runtime adapter.
' Native runtime ux_mem extern sembolunu bekler; interpreter ise lokal array kullanir.
' Bu adapter, runtime servislerini interpreter array belleğine bağlamak için üretildi.
Declare Sub uxm_entry()
Declare Sub ux_putc(ByVal ch As ULongInt)
Declare Function ux_getc() As ULongInt
Declare Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt)
Declare Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr)
Declare Sub ux_runtime_error(ByVal code As ULongInt)

Const UXM_INTERP_MEM_BYTES As ULongInt = 64UL * 1024UL
Dim Shared ux_mem(0 To UXM_INTERP_MEM_BYTES-1) As UByte
Dim Shared ux_status As UByte
Dim Shared ux_flags As UShort
Dim Shared ux_ptr As ULongInt
Dim Shared ux_sp As ULongInt
Dim Shared ux_cell_bits As ULong = 8
Dim Shared ux_cell_bytes As ULong = 1
Dim Shared ux_tape_cells As ULong = 32768
Dim Shared ux_stack_cells As ULong = 8192
Dim Shared ux_data_cells As ULong = 24576
Dim Shared ux_queue_cells As ULong = 4096
Dim Shared ux_stack_offset As ULong = 32768
Dim Shared ux_data_offset As ULong = 32768 + 8192

'''
        self.write_text(self.out / "src/interpreter/interpreter_runtime_adapter_64k.bas", prepend + rf, "interpreter", "runtime full adapteri üretildi.")

        # 3) patch interpreter include and remove old memory globals.
        def patch_interp(txt: str) -> str:
            txt = txt.replace('#Include Once "../runtime/uxm31_runtime_fb_full.bas"', '#Include Once "interpreter_runtime_adapter_64k.bas"')
            # remove old 16MB local memory/global block
            txt = re.sub(
                r'Const\s+UXM_INTERP_MEM_BYTES\s+As\s+ULongInt\s*=\s*16UL\s*\*\s*1024UL\s*\*\s*1024UL\s*\n'
                r'Dim\s+Shared\s+ux_mem\(0\s+To\s+UXM_INTERP_MEM_BYTES-1\)\s+As\s+UByte\s*\n'
                r'Dim\s+Shared\s+ux_status\s+As\s+UByte\s*\n'
                r'Dim\s+Shared\s+ux_flags\s+As\s+UShort\s*\n'
                r'Dim\s+Shared\s+ux_ptr\s+As\s+ULongInt\s*\n'
                r'Dim\s+Shared\s+ux_sp\s+As\s+ULongInt\s*\n'
                r'Dim\s+Shared\s+ux_cell_bits\s+As\s+ULong\s*=\s*8\s*\n'
                r'Dim\s+Shared\s+ux_cell_bytes\s+As\s+ULong\s*=\s*1\s*\n'
                r'Dim\s+Shared\s+ux_tape_cells\s+As\s+ULong\s*=\s*1048576\s*\n'
                r'Dim\s+Shared\s+ux_stack_cells\s+As\s+ULong\s*=\s*262144\s*\n'
                r'Dim\s+Shared\s+ux_data_cells\s+As\s+ULong\s*=\s*4194304\s*\n'
                r'Dim\s+Shared\s+ux_queue_cells\s+As\s+ULong\s*=\s*262144\s*\n'
                r'Dim\s+Shared\s+ux_stack_offset\s+As\s+ULong\s*=\s*1048576\s*\n'
                r'Dim\s+Shared\s+ux_data_offset\s+As\s+ULong\s*=\s*1048576\s*\+\s*262144\s*\n',
                "' UXM-A-64K: bellek ve runtime servis bağlantısı interpreter_runtime_adapter_64k.bas içinde tanımlanır.\n",
                txt,
                flags=re.I,
            )
            return txt

        self.patch_file(interp, patch_interp, "interpreter", "Interpreter 64KB adaptere bağlandı.")

    def copy_vscode_artifacts(self) -> None:
        if "v15tools" not in self.packages:
            self.actions.append(Action("vscode", "SKIP", "<v15tools>", "tools/vscode_release", "SKIP", "V15 tools paketi bulunamadı."))
            return
        pkg = self.packages["v15tools"]
        try:
            # choose directory containing package.json and extension.js under vscode
            candidates = [p for p in pkg.rglob("package.json") if "vscode" in str(p).lower()]
            if not candidates:
                raise BuildError("V15 vscode package.json bulunamadı")
            src_dir = sorted([p.parent for p in candidates], key=lambda p: len(str(p)))[0]
            self.copy_tree(src_dir, self.out / "tools/vscode_release/uxm-dil-destegi-v15", "vscode", "Kurulabilir VSCode artifact.")
        except Exception as e:
            self.actions.append(Action("vscode", "SKIP", str(pkg), "tools/vscode_release", "ERROR", str(e)))

    def copy_tests_and_tools(self) -> None:
        # Final expected tests
        if "final_tests" in self.packages:
            pkg = self.packages["final_tests"]
            # copy only uxm/tests if possible; otherwise all package as archive source
            try:
                src = self.find_dir_named(pkg, "uxm/tests")
                self.copy_tree(src, self.out / "tests/final_expected", "tests", "Final expected suite seçici kopya.")
            except Exception:
                self.copy_tree(pkg, self.out / "tests/final_expected_package", "tests", "Final expected paket bütün kopya.")
        else:
            self.actions.append(Action("tests", "SKIP", "<final_tests>", "tests/final_expected", "SKIP", "24 final expected paketi bulunamadı."))

        # Release gate 47 or 51
        if "release_gate" in self.packages:
            self.copy_tree(self.packages["release_gate"], self.out / "tools/release_gate_v20", "tools", "V20 release gate araçları.")
        # V22 command fix
        if "v22_fix" in self.packages:
            self.copy_tree(self.packages["v22_fix"], self.out / "tools/ps1_bat_fix_v22", "tools", "V22 PS1/BAT onarım paketi.")

    def create_gate_scripts(self) -> None:
        bat = r'''@echo off
setlocal
cd /d "%~dp0"
if not exist build mkdir build

echo [1/4] FreeBASIC native compiler derleme
fbc src\uxm_v20_native_compiler.bas -x build\uxm_a64_native_compiler.exe
if errorlevel 1 goto fail

echo [2/4] FreeBASIC runtime object derleme
fbc src\uxm_v20_runtime.bas -c -o build\uxm_a64_runtime.o
if errorlevel 1 goto fail

echo [3/4] Placeholder ve 64KB statik kapi
python tools\uxm_a64_static_gate.py
if errorlevel 1 goto fail

echo [4/4] Bitti. NASM/EXE smoke testlerini ortam pathlerine gore calistirin.
goto end

:fail
echo HATA: UXM-A-64K gate basarisiz.
exit /b 1
:end
endlocal
'''
        self.write_text(self.out / "build_a64_gate.bat", bat, "tools", "Windows build/gate betiği.")

        gate_py = r'''#!/usr/bin/env python3
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
'''
        self.write_text(self.out / "tools/uxm_a64_static_gate.py", gate_py, "tools", "Statik 64KB/placeholder kapısı.")

    # ---------- Reports ----------
    def collect_source_metrics(self) -> list[dict]:
        rows = []
        for p in sorted((self.out / "src").rglob("*")):
            if not p.is_file():
                continue
            if p.suffix.lower() not in [".bas", ".bi", ".ts", ".json"]:
                continue
            txt = p.read_text(encoding=UTF8, errors="ignore")
            rows.append({
                "path": str(p.relative_to(self.out)).replace("\\", "/"),
                "bytes": p.stat().st_size,
                "lines": txt.count("\n") + 1,
                "sha256": self.sha(p)[:16],
                "placeholder_hits": sum(txt.lower().count(w.lower()) for w in PLACEHOLDER_WORDS),
                "include_count": len(re.findall(r'(?im)^\s*#Include', txt)),
                "function_sub_count": len(re.findall(r'(?im)^\s*(Function|Sub)\s+', txt)),
                "case_count": len(re.findall(r'(?im)^\s*Case\s+', txt)),
            })
        return rows

    def check_declared_implemented(self) -> tuple[list[str], list[str]]:
        decl: dict[str, list[str]] = {}
        impl: dict[str, list[str]] = {}
        for p in (self.out / "src").rglob("*"):
            if p.suffix.lower() not in [".bas", ".bi"] or not p.is_file():
                continue
            txt = p.read_text(encoding=UTF8, errors="ignore")
            for i, line in enumerate(txt.splitlines(), 1):
                m = re.match(r'\s*Declare\s+(?:Sub|Function)\s+([A-Za-z_][A-Za-z0-9_]*)\b', line, re.I)
                if m:
                    decl.setdefault(m.group(1).lower(), []).append(f"{p.relative_to(self.out)}:{i}")
                if not line.lstrip().lower().startswith("declare"):
                    m = re.match(r'\s*(?:Export\s+)?(?:Sub|Function)\s+([A-Za-z_][A-Za-z0-9_]*)\b', line, re.I)
                    if m:
                        impl.setdefault(m.group(1).lower(), []).append(f"{p.relative_to(self.out)}:{i}")
        missing = [f"{k} <- {', '.join(v[:3])}" for k, v in sorted(decl.items()) if k not in impl]
        duplicate = [f"{k} -> {', '.join(v[:5])}" for k, v in sorted(impl.items()) if len(v) > 1]
        return missing, duplicate

    def check_includes(self) -> list[str]:
        missing = []
        inc_re = re.compile(r'(?im)^\s*#Include(?:\s+Once)?\s+"([^"]+)"')
        for p in (self.out / "src").rglob("*"):
            if p.suffix.lower() not in [".bas", ".bi"] or not p.is_file():
                continue
            txt = p.read_text(encoding=UTF8, errors="ignore")
            for inc in inc_re.findall(txt):
                target = (p.parent / inc).resolve()
                if not target.exists():
                    missing.append(f"{p.relative_to(self.out)} -> {inc}")
        return missing

    def write_reports(self) -> None:
        rep_dir = self.out / "reports"
        rep_dir.mkdir(parents=True, exist_ok=True)
        # actions csv/json
        action_csv = rep_dir / "UXM_A64_MERGE_ACTIONS.csv"
        with action_csv.open("w", encoding="utf-8-sig", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(asdict(self.actions[0]).keys()) if self.actions else ["layer"])
            w.writeheader()
            for a in self.actions:
                w.writerow(asdict(a))
        (rep_dir / "UXM_A64_MERGE_ACTIONS.json").write_text(json.dumps([asdict(a) for a in self.actions], indent=2, ensure_ascii=False), encoding=UTF8)

        metrics = self.collect_source_metrics()
        metrics_csv = rep_dir / "UXM_A64_SOURCE_METRICS.csv"
        with metrics_csv.open("w", encoding="utf-8-sig", newline="") as f:
            if metrics:
                w = csv.DictWriter(f, fieldnames=list(metrics[0].keys()))
                w.writeheader(); w.writerows(metrics)

        missing_decl, duplicate_impl = self.check_declared_implemented()
        missing_includes = self.check_includes()

        fbc = shutil.which("fbc") or ""
        nasm = shutil.which("nasm") or ""
        summary = []
        summary.append("# UXM-A-64K Kurulum Raporu")
        summary.append("")
        summary.append(f"Root: `{self.root}`")
        summary.append(f"Output: `{self.out}`")
        summary.append("")
        summary.append("## Paketler")
        for k, v in self.packages.items():
            summary.append(f"- {k}: `{v.name}`")
        summary.append("")
        summary.append("## Mimari karar")
        summary.append("- Base: V20 temiz `src` mimarisi.")
        summary.append("- Native compiler: Stage12 gelişmiş split dosyaları + 64KB patch.")
        summary.append("- Runtime: V20/V18/V19 birleşik servisleri.")
        summary.append("- Interpreter: 64KB adapter üretildi; native runtime extern sembolü yerine lokal array bellek kullanır.")
        summary.append("- VSCode: V20 TS kaynak + varsa V15 kurulabilir artifact.")
        summary.append("")
        summary.append("## Statik kapılar")
        summary.append(f"- Eksik include sayısı: {len(missing_includes)}")
        summary.append(f"- Declare edilip implementasyonu bulunmayan isim sayısı: {len(missing_decl)}")
        summary.append(f"- Çift implementasyon adı sayısı: {len(duplicate_impl)}")
        summary.append(f"- fbc bulundu mu: {'Evet: '+fbc if fbc else 'Hayır'}")
        summary.append(f"- nasm bulundu mu: {'Evet: '+nasm if nasm else 'Hayır'}")
        summary.append("")
        if missing_includes:
            summary.append("### Eksik include listesi")
            for x in missing_includes[:100]: summary.append(f"- {x}")
            if len(missing_includes) > 100: summary.append(f"- ... {len(missing_includes)-100} kayıt daha")
            summary.append("")
        if missing_decl:
            summary.append("### Declare var, implementasyon bulunamadı")
            for x in missing_decl[:100]: summary.append(f"- {x}")
            if len(missing_decl) > 100: summary.append(f"- ... {len(missing_decl)-100} kayıt daha")
            summary.append("")
        if duplicate_impl:
            summary.append("### Çift implementasyon adları")
            summary.append("Bunların bir kısmı bilinçli olabilir; özellikle interpreter callbackleri/runtime callbackleri ayrı hatlarda çakışabilir.")
            for x in duplicate_impl[:100]: summary.append(f"- {x}")
            if len(duplicate_impl) > 100: summary.append(f"- ... {len(duplicate_impl)-100} kayıt daha")
            summary.append("")
        summary.append("## Sonraki gerçek doğrulama")
        summary.append("Windows ortamında `build_a64_gate.bat` çalıştır. Bu script önce FreeBASIC derlemesi, sonra statik 64KB kapısını çalıştırır.")
        summary.append("")
        (rep_dir / "UXM_A64_BUILD_REPORT.md").write_text("\n".join(summary), encoding=UTF8)
        self.log(f"Rapor yazıldı: {rep_dir / 'UXM_A64_BUILD_REPORT.md'}")


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="UXM-A 64KB hattını açık zip klasörlerinden kurar.")
    parser.add_argument("--root", default=".", help="Açılmış zip klasörlerinin bulunduğu uçma klasörü. Varsayılan: programın çalıştığı klasör.")
    parser.add_argument("--out", default="UXM_A_64K", help="Oluşturulacak çalışma klasörü. Varsayılan: UXM_A_64K")
    parser.add_argument("--force", action="store_true", help="Çıkış klasörü varsa silip yeniden oluştur.")
    parser.add_argument("--dry-run", action="store_true", help="Dosya yazmadan sadece işlem planını dene.")
    parser.add_argument("--quiet", action="store_true", help="Az çıktı ver.")
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    out = Path(args.out)
    if not out.is_absolute():
        out = root / out

    try:
        builder = UXMA64KBuilder(root=root, out=out, force=args.force, dry_run=args.dry_run, verbose=not args.quiet)
        builder.run()
        return 0
    except BuildError as e:
        print(f"HATA: {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"BEKLENMEYEN HATA: {type(e).__name__}: {e}", file=sys.stderr)
        return 3

if __name__ == "__main__":
    raise SystemExit(main())
