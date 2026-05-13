import os
import re
from collections import Counter
from pathlib import Path

class UXM_ASM_Intelligence:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.asm_dir = self.pick_asm_dir()
        self.opt_dir = self.base_path / "yeni_optimize_asm"
        self.report_dir = self.base_path / "optimizasyon"
        for d in [self.opt_dir, self.report_dir, self.base_path / "build" / "obj", self.base_path / "build" / "exe"]:
            d.mkdir(parents=True, exist_ok=True)

    def pick_asm_dir(self):
        # Önce aktif build\\asm. Yoksa en yeni "build stage N\\asm".
        active = self.base_path / "build" / "asm"
        if active.exists():
            return active
        candidates = []
        for d in self.base_path.iterdir():
            if d.is_dir() and d.name.lower().startswith("build") and (d / "asm").exists():
                candidates.append((d.stat().st_mtime, d / "asm"))
        return max(candidates)[1] if candidates else active

    def get_clean_instr(self, line):
        line = line.split(';')[0].strip()
        if not line or line.endswith(':'):
            return None
        return line

    def analyze_patterns(self, lines):
        instr_list = [x for x in (self.get_clean_instr(line) for line in lines) if x]
        bigrams = [f"{instr_list[i]} -> {instr_list[i+1]}" for i in range(len(instr_list)-1)]
        trigrams = [f"{instr_list[i]} -> {instr_list[i+1]} -> {instr_list[i+2]}" for i in range(len(instr_list)-2)]
        stats = {
            "top_instr": Counter(instr_list).most_common(20),
            "top_bigrams": Counter(bigrams).most_common(20),
            "top_trigrams": Counter(trigrams).most_common(20),
            "jump_density": len([x for x in instr_list if x.lower().startswith(('j','call'))]) / (len(instr_list) + 1),
        }
        return stats, instr_list

    def apply_safe_rules(self, lines):
        optimized = []
        i = 0
        while i < len(lines):
            raw = lines[i].rstrip('\n')
            line = raw.strip()
            # Çok güvenli: mov reg,0 -> xor reg,reg. Bellek hedefinde uygulama yok.
            m = re.fullmatch(r"mov\s+(r(?:ax|bx|cx|dx|si|di|8|9|10|11|12|13|14|15)|e(?:ax|bx|cx|dx|si|di)|[abcd]x),\s*0", line, re.I)
            if m:
                reg = m.group(1)
                optimized.append(f"xor {reg}, {reg} ; [UXM_SAFE mov-zero]")
                i += 1
                continue
            # Çok güvenli: jmp hemen sonraki etikete gidiyorsa sil.
            if line.lower().startswith('jmp ') and i + 1 < len(lines):
                label = line.split()[-1].strip()
                if lines[i+1].strip() == label + ':':
                    optimized.append(f"; [UXM_SAFE removed jmp-to-next] {line}")
                    i += 1
                    continue
            optimized.append(raw)
            i += 1
        return optimized

    def run(self):
        if not self.asm_dir.exists():
            raise FileNotFoundError(f"ASM klasoru yok: {self.asm_dir}")
        full_report = self.report_dir / "asm_intel_report.txt"
        with full_report.open("w", encoding="utf-8") as rep:
            rep.write(f"ASM Kaynak Klasoru: {self.asm_dir}\n")
            for file in sorted(self.asm_dir.glob("*.asm")):
                content = file.read_text(encoding="utf-8", errors="replace").splitlines()
                stats, _ = self.analyze_patterns(content)
                optimized = self.apply_safe_rules(content)
                rep.write(f"\nANALIZ: {file.name}\n" + "="*40 + "\n")
                rep.write("Sik Kullanilan Bigramlar:\n")
                for b, c in stats['top_bigrams']:
                    rep.write(f" - {c} kez: {b}\n")
                rep.write(f"Jump/Call Yogunlugu: %{stats['jump_density']*100:.2f}\n")
                (self.opt_dir / file.name).write_text("\n".join(optimized), encoding="utf-8")
        print(f"İşlem tamam. Rapor: {full_report}")

if __name__ == "__main__":
    UXM_ASM_Intelligence(os.getcwd()).run()
