import os
import subprocess
import time
from pathlib import Path


def pick_fbc():
    for key in ("UXM_FBC", "FBC"):
        val = os.environ.get(key)
        if val and Path(val).exists():
            return val
    known = Path(r"C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe")
    return str(known) if known.exists() else "fbc"


def run_command(cmd):
    start = time.perf_counter()
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return time.perf_counter() - start, result.returncode, result.stdout, result.stderr


def q(p):
    return '"' + str(p) + '"'


def build_and_monitor():
    base_path = Path(os.getcwd())
    opt_asm_dir = base_path / "yeni_optimize_asm"
    obj_dir = base_path / "build" / "obj"
    exe_dir = base_path / "build" / "exe"
    obj_dir.mkdir(parents=True, exist_ok=True)
    exe_dir.mkdir(parents=True, exist_ok=True)
    fbc = pick_fbc()
    nasm = "nasm"
    runtime = base_path / "uxm" / "core" / "runtime" / "uxm31_runtime_fb_full.bas"

    print("=== UXM OPTIMIZE DERLEME VE IZLEME SISTEMI ===")
    if not opt_asm_dir.exists():
        print("Hata: yeni_optimize_asm klasoru bulunamadi!")
        return 1
    if not runtime.exists():
        print(f"Hata: runtime bulunamadi: {runtime}")
        return 1

    fail = 0
    for asm_path in sorted(opt_asm_dir.glob("*.asm")):
        name = asm_path.stem
        if name.lower() == "program":
            # Smoke testlerden kalan program.asm özel dosyadır; optimizer karşılaştırması için zorunlu değil.
            pass
        obj_path = obj_dir / f"{name}.o"
        exe_path = exe_dir / f"{name}_opt.exe"
        print(f"\n[ISLENIYOR]: {name}")
        cmd_nasm = f'{nasm} -f win64 {q(asm_path)} -o {q(obj_path)}'
        t_nasm, code_nasm, _, err_nasm = run_command(cmd_nasm)
        if code_nasm:
            print(f"  > NASM HATASI ({t_nasm:.2f} sn): {err_nasm}")
            fail += 1
            continue
        print(f"  > NASM Basarili ({t_nasm:.2f} sn)")
        cmd_link = f'{q(fbc)} {q(runtime)} {q(obj_path)} -x {q(exe_path)}'
        t_link, code_link, _, err_link = run_command(cmd_link)
        if code_link:
            print(f"  > LINK HATASI ({t_link:.2f} sn): {err_link}")
            fail += 1
            continue
        print(f"  > LINK Basarili ({t_link:.2f} sn)")
        t_exec, code_exec, out_exec, err_exec = run_command(q(exe_path))
        print(f"  > CALISMA SURESI: {t_exec:.4f} sn | code={code_exec}")
        print(f"  > CIKTI: {out_exec.strip()}")
    return 1 if fail else 0


if __name__ == "__main__":
    raise SystemExit(build_and_monitor())
