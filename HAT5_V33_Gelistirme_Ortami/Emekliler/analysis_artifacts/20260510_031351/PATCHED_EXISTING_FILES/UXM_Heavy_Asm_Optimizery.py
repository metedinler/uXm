import os
from pathlib import Path

class UXM_Final_Optimizer:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.opt_dir = self.base_path / "optimizasyon"
        self.intel_report = self.opt_dir / "asm_intel_report.txt"
        self.output_file = self.opt_dir / "sihirli_asm_onerileri.txt"
        self.opt_dir.mkdir(parents=True, exist_ok=True)

    def analyze_and_suggest(self):
        intel_data = self.intel_report.read_text(encoding="utf-8", errors="replace") if self.intel_report.exists() else ""
        suggestions = [
            "=== UXM ASM OPTIMIZASYON STRATEJI KITABI ===",
            "Durum: Bu dosya öneri üretir; kaynak kodu otomatik bozmaz.",
            "",
            "[SAFE-1] mov reg, 0 -> xor reg, reg",
            "  Uygulama: sadece register hedefte. Memory hedefte uygulanmaz.",
            "",
            "[SAFE-2] jmp hemen sonraki label -> sil",
            "  Uygulama: jmp hedefi bir sonraki satırdaki etiketse.",
            "",
            "[GUARDED-1] push/pop kaldırma",
            "  Uygulama: aradaki blok stack pointer'a, call'a veya aynı register'a dokunmuyorsa.",
            "",
            "[GUARDED-2] add/sub reg,1 -> inc/dec",
            "  Dikkat: flag semantiği önemliyse uygulanmaz. UXM flag üretimi ayrıysa uygulanır.",
            "",
            "[EMITTER-1] Runtime servis çağrılarında sıcak meta id için özel fast path",
            "  Örnek: @ADD, @PRINT_CHAR, @TENSOR_GET gibi sık çağrılan servisler.",
            "",
            "[EMITTER-2] Tensor/sparse döngülerinde sınır kontrolünü loop dışına taşı",
            "  Dikkat: taşmadan emin olunmadan otomatik uygulanmaz.",
        ]
        if "mov dx, word [ux_flags]" in intel_data:
            suggestions.append("\n[TESPIT] ux_flags bellek trafiği raporda görünüyor; register cache aday.")
        if "cmp r10" in intel_data or "jae" in intel_data:
            suggestions.append("[TESPIT] sınır kontrol/jump yoğunluğu yüksek; loop hoisting aday.")
        self.output_file.write_text("\n".join(suggestions), encoding="utf-8")
        return f"Öneri kitabı yazıldı: {self.output_file}"

class UXM_Heavy_Optimizer:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.opt_dir = self.base_path / "optimizasyon"
        self.output_file = self.opt_dir / "strateji_kitabi_v2.txt"
        self.opt_dir.mkdir(parents=True, exist_ok=True)
        self.rules = []
        self.seed_rules()

    def add_rule(self, title, detect, solve, gain, safety="GUARDED"):
        self.rules.append({"title": title, "detect": detect, "solve": solve, "gain": gain, "safety": safety})

    def seed_rules(self):
        self.add_rule("Zero idiom", "mov r64/e32,0", "xor reg,reg", "%1-3", "SAFE")
        self.add_rule("Jump to next", "jmp L; L:", "jmp satırını sil", "%0.5-2", "SAFE")
        self.add_rule("Redundant stack traffic", "push R ... pop R", "yalnız call/stack/register güvenlik kontrolünden sonra sil", "%1-8")
        self.add_rule("Loop bound hoisting", "her iterasyonda cmp/jae", "toplam boyutu loop öncesi doğrula", "%5-25")
        self.add_rule("Service fast path", "sık meta CALL", "dispatcher yerine direkt servis stub", "%5-20")
        self.add_rule("Constant scale", "imul reg, 2/4/8/16", "lea/shl kullan", "%1-6")
        self.add_rule("Dead write", "mov reg,A; mov reg,B", "ilk write'ı sil", "%1-4")
        self.add_rule("Register cache flags", "ux_flags tekrar tekrar load/store", "r15w gibi callee-save register cache", "%5-15")
        self.add_rule("Tensor linear address", "çoklu imul/add adres hesabı", "stride ön hesapla", "%5-30")
        self.add_rule("Sparse vector hot loop", "nnz döngüsü içinde pointer servis çağrısı", "doğrudan memory lane veya batched servis", "%10-40")

    def build_report(self):
        content = ["=== UXM AGIR SIKLET OPTIMIZASYON KURAL KITABI V2 ===", f"Kural Sayısı: {len(self.rules)}", ""]
        for idx, rule in enumerate(self.rules, 1):
            content += [f"[{idx}] {rule['title']} [{rule['safety']}]", f"Tespit: {rule['detect']}", f"Çözüm: {rule['solve']}", f"Tahmini Verim: {rule['gain']}", "-"*50]
        self.output_file.write_text("\n".join(content), encoding="utf-8")
        return f"Rapor yazıldı: {self.output_file}"

if __name__ == "__main__":
    path = os.getcwd()
    print(UXM_Final_Optimizer(path).analyze_and_suggest())
    print(UXM_Heavy_Optimizer(path).build_report())
