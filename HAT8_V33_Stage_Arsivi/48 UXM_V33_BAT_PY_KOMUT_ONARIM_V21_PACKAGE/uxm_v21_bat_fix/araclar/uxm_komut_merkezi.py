# -*- coding: utf-8 -*-
"""
UX-MINIMA x64 Türkçe Komut Merkezi v21
- Tüm .bat sarmalayıcıları bu dosyaya bağlanır.
- Kısa anahtarlar Türkçe ve İngilizce aliaslarla desteklenir.
- Eski -k kullanımını kırmamak için: -k tek başına verilirse 'derleme-yok' kabul edilir;
  tercih edilen yeni kullanım: -d / --derleme-yok.
"""
from __future__ import annotations
import argparse
import csv
import os
import re
import subprocess
import sys
from pathlib import Path
from datetime import datetime

try:
    csv.field_size_limit(1024 * 1024 * 64)
except Exception:
    pass

KOD_OK = 0
KOD_HATA = 1
KOD_BULGU = 2

ANAHTAR_YARDIM = """
Kullanım / Usage:
  <komut>.bat [seçenekler]

Genel seçenekler / General options:
  -h,        --help                         Yardım ekranını gösterir.
  -k,        --kok <yol>                    Proje kök dizini. Örnek: -k C:\\UXMv33
  -d,        --derleme-yok, --no-build       Derleyiciyi yeniden derlemeden test koşar.
  -D,        --ilk-hatada-dur, --stop-on-fail İlk hatada durur.
  -n,        --adet, --limit <sayı>          Koşulacak test sayısını sınırlar.
  -s,        --basla, --from-index <sayı>    Test listesindeki başlangıç indeksi.
  -a,        --ara, --name-contains <metin>  Dosya adında/metinde geçen testleri seçer.
  -z,        --zaman, --timeout-test <sn>    Tek test zaman aşımı süresi.
  -t,        --test-klasoru <yol>            Test klasörü.
  -c,        --cikti <yol>                   Rapor/sonuç çıkış klasörü.
  -u,        --uygula, --apply               Gerçek değişiklik uygular.
  -b,        --build-emekli, --retire-build  Build klasörünü emekliye alır.

Önemli not:
  Komut içine 'cd' yazılmaz. Önce dizine girilir, sonra komut çalıştırılır.
  Yanlış:  .\\stage21_placeholder_test.bat -k cd C:\\UXMv33
  Doğru:   cd C:\\UXMv33
           .\\stage21_placeholder_test.bat -d
  Kök yol belirtmek gerekiyorsa:
           .\\stage21_placeholder_test.bat -k C:\\UXMv33 -d

Eski uyumluluk:
  Önceki paketlerde -k 'derleme-yok' gibi kullanıldı. Bu hatalıydı.
  V21'de -k değer almadan verilirse geçici olarak derleme-yok sayılır ve uyarı basılır.
  Yeni doğru kısa anahtar: -d
""".strip()

KOMUTLAR = {
    "yardim": "Yardım ekranı",
    "derleyici_derle": "Derleyiciyi/build hattını kontrol eder",
    "bellek": "Bellek modeli testleri",
    "tum": "Tüm/ana test kümesi",
    "hizli_tara": "Son CSV içinden hatalı test manifesti üretir",
    "hatali": "Hızlı taramada bulunan hatalı testleri yeniden koşar",
    "placeholder_tara": "Placeholder/TODO/dummy/stub tarar",
    "placeholder_kapi": "Placeholder bulursa hata kodu döndürür",
    "stage_test": "Belirli stage test klasörünü koşar",
    "performans": "Basit performans/timing raporu üretir",
}

TEST_KLASORLERI = {
    "bellek": "uxm/tests/bellek_v11",
    "tum": "uxm/tests/all_expected_known",
    "stage17": "uxm/tests/stage17",
    "stage18": "uxm/tests/stage18",
    "stage19": "uxm/tests/stage19",
    "stage20": "uxm/tests/stage20_final",
    "stage21_placeholder": "uxm/tests/stage21_placeholder_real",
    "stage22_placeholder": "uxm/tests/stage22_placeholder_real",
    "stage23_placeholder": "uxm/tests/stage23_placeholder_real",
    "stage24_placeholder": "uxm/tests/stage24_placeholder_v19",
}

CIKTI_ADLARI = {
    "bellek": "sonuclar_bellek",
    "tum": "sonuclar_tum",
    "hatali": "sonuclar_hatali",
    "stage17": "sonuclar_stage17",
    "stage18": "sonuclar_stage18",
    "stage19": "sonuclar_stage19",
    "stage20": "sonuclar_stage20",
    "stage21_placeholder": "sonuclar_stage21_placeholder",
    "stage22_placeholder": "sonuclar_stage22_placeholder",
    "stage23_placeholder": "sonuclar_stage23_placeholder",
    "stage24_placeholder": "sonuclar_stage24_placeholder",
}

class Ayarlar:
    def __init__(self, argv: list[str]):
        self.raw = list(argv)
        self.help = False
        self.kok: Path | None = None
        self.derleme_yok = False
        self.ilk_hatada_dur = False
        self.adet: str | None = None
        self.basla: str | None = None
        self.ara: str | None = None
        self.zaman: str | None = None
        self.test_klasoru: str | None = None
        self.cikti: str | None = None
        self.uygula = False
        self.build_emekli = False
        self.bilinmeyen: list[str] = []
        self.uyarilar: list[str] = []
        self.parse(argv)

    def _deger_al(self, args: list[str], i: int, ad: str) -> tuple[str | None, int]:
        if i + 1 >= len(args) or args[i + 1].startswith("-"):
            self.uyarilar.append(f"{ad} için değer verilmedi.")
            return None, i
        return args[i + 1], i + 1

    def parse(self, args: list[str]) -> None:
        i = 0
        while i < len(args):
            a = args[i]
            if a in ("-h", "--help", "/?", "-?", "yardim", "help"):
                self.help = True
            elif a in ("-k", "--kok", "--root"):
                # Geriye uyum: -k tek başınaysa eski kullanıcı alışkanlığı için derleme-yok say.
                if i + 1 >= len(args) or args[i + 1].startswith("-"):
                    self.derleme_yok = True
                    self.uyarilar.append("-k değer almadan kullanıldı; V21 geçici uyumluluk için 'derleme-yok' saydı. Yeni kullanım: -d")
                else:
                    val, i = self._deger_al(args, i, a)
                    if val:
                        self.kok = Path(val).expanduser()
            elif a in ("-d", "--derleme-yok", "--no-build", "--nobuild"):
                self.derleme_yok = True
            elif a in ("-D", "--ilk-hatada-dur", "--stop-on-fail"):
                self.ilk_hatada_dur = True
            elif a in ("-n", "--adet", "--limit"):
                val, i = self._deger_al(args, i, a); self.adet = val
            elif a in ("-s", "--basla", "--from-index"):
                val, i = self._deger_al(args, i, a); self.basla = val
            elif a in ("-a", "--ara", "--name-contains"):
                val, i = self._deger_al(args, i, a); self.ara = val
            elif a in ("-z", "--zaman", "--timeout-test"):
                val, i = self._deger_al(args, i, a); self.zaman = val
            elif a in ("-t", "--test-klasoru", "--test-dir"):
                val, i = self._deger_al(args, i, a); self.test_klasoru = val
            elif a in ("-c", "--cikti", "--out", "--out-root"):
                val, i = self._deger_al(args, i, a); self.cikti = val
            elif a in ("-u", "--uygula", "--apply"):
                self.uygula = True
            elif a in ("-b", "--build-emekli", "--retire-build"):
                self.build_emekli = True
            elif a.lower() == "cd":
                self.uyarilar.append("Komut satırına 'cd' yazılmış; bu atlandı. Önce ayrı satırda cd <dizin> kullan.")
                # cd'den sonra gelen yolu da atla
                if i + 1 < len(args) and not args[i + 1].startswith("-"):
                    i += 1
            else:
                self.bilinmeyen.append(a)
            i += 1


def print_help(komut: str | None = None) -> None:
    print("UX-MINIMA x64 Komut Yardımı")
    print("=" * 34)
    if komut:
        print(f"Komut: {komut}\n")
    print(ANAHTAR_YARDIM)
    print("\nKomutlar:")
    for k, v in KOMUTLAR.items():
        print(f"  {k:<22} {v}")


def kok_bul(ayar: Ayarlar) -> Path:
    if ayar.kok:
        return ayar.kok.resolve()
    # Bu dosya araclar içindeyse proje kökü bir üst dizindir.
    return Path(__file__).resolve().parents[1]


def yaz_uyari(ayar: Ayarlar) -> None:
    for u in ayar.uyarilar:
        print(f"[UYARI] {u}")
    if ayar.bilinmeyen:
        print(f"[UYARI] Tanınmayan anahtar/değer atlandı: {' '.join(ayar.bilinmeyen)}")


def runner_bul(kok: Path) -> Path | None:
    adaylar = [
        kok / "tools" / "UXM_EXPECT_RUNNER_V6.py",
        kok / "tools" / "UXM_EXPECT_RUNNER_V5.py",
        kok / "tools" / "UXM_EXPECT_RUNNER_V4.py",
        kok / "tools" / "UXM_EXPECT_RUNNER_V3.py",
        kok / "tools" / "UXM_EXPECT_RUNNER_V2.py",
        kok / "UXM_EXPECT_RUNNER_V2.py",
    ]
    for p in adaylar:
        if p.exists():
            return p
    return None


def python_cmd() -> str:
    return sys.executable or "python"


def run_subprocess(cmd: list[str], cwd: Path) -> int:
    print("[KOMUT] " + " ".join(f'"{c}"' if " " in c else c for c in cmd))
    try:
        return subprocess.call(cmd, cwd=str(cwd))
    except KeyboardInterrupt:
        print("[KESİLDİ] Kullanıcı işlemi durdurdu.")
        return 130


def test_kos(ayar: Ayarlar, preset: str | None = None) -> int:
    kok = kok_bul(ayar)
    yaz_uyari(ayar)
    if ayar.help:
        print_help(preset or "test")
        return KOD_OK
    runner = runner_bul(kok)
    if not runner:
        print("[HATA] Test runner bulunamadı: tools/UXM_EXPECT_RUNNER_V6.py veya benzeri yok.")
        return KOD_HATA
    test_dir = ayar.test_klasoru or (TEST_KLASORLERI.get(preset or "") if preset else None)
    manifest = None
    if preset == "hatali":
        manifest_path = kok / "hizli_sonuclar" / "son" / "hatali_tekil_manifest.csv"
        if manifest_path.exists():
            manifest = str(manifest_path)
        else:
            print("[BİLGİ] Hatalı manifest yok; önce hizli_tara.bat çalıştırılıyor.")
            hizli_tara(ayar)
            if manifest_path.exists():
                manifest = str(manifest_path)
    if not test_dir and not manifest:
        print("[HATA] Test klasörü veya manifest belirtilmedi. Örnek: --test-klasoru uxm\\tests\\stage20_final")
        return KOD_HATA
    out_root = ayar.cikti or CIKTI_ADLARI.get(preset or "", "sonuclar_test")
    cmd = [python_cmd(), str(runner), "--root", str(kok), "--out-root", str(kok / out_root)]
    if manifest:
        cmd += ["--manifest", manifest]
    else:
        cmd += ["--test-dir", str(kok / test_dir)]
    if ayar.derleme_yok:
        cmd.append("--no-build")
    if ayar.ilk_hatada_dur:
        cmd.append("--stop-on-fail")
    if ayar.adet:
        cmd += ["--limit", ayar.adet]
    if ayar.basla:
        cmd += ["--from-index", ayar.basla]
    if ayar.ara:
        cmd += ["--name-contains", ayar.ara]
    if ayar.zaman:
        cmd += ["--timeout-test", ayar.zaman]
    return run_subprocess(cmd, kok)


def son_csv_bul(kok: Path, source: str | None = None) -> Path | None:
    if source:
        p = Path(source)
        if not p.is_absolute():
            p = kok / p
        return p if p.exists() else None
    adaylar: list[Path] = []
    for pat in [
        "sonuclar_tum/**/sonuclar.csv",
        "sonuclar_hatali/**/sonuclar.csv",
        "sonuclar_bellek/**/sonuclar.csv",
        "sonuclar_stage*/**/sonuclar.csv",
        "expected_results*/**/expected_results*.csv",
        "fast_results/runs/**/sonuclar.csv",
    ]:
        adaylar.extend(kok.glob(pat))
    if not adaylar:
        return None
    return max(adaylar, key=lambda p: p.stat().st_mtime)


def row_get(row: dict, *names: str) -> str:
    lower = {str(k).lower(): v for k, v in row.items()}
    for n in names:
        if n in row and row[n] is not None:
            return str(row[n])
        if n.lower() in lower and lower[n.lower()] is not None:
            return str(lower[n.lower()])
    return ""


def status_bad(status: str) -> bool:
    s = (status or "").strip().lower()
    if not s:
        return True
    iyi = {"basarili", "başarılı", "passed", "pass", "ok", "success"}
    return s not in iyi


def hizli_tara(ayar: Ayarlar) -> int:
    kok = kok_bul(ayar)
    yaz_uyari(ayar)
    if ayar.help:
        print_help("hizli_tara")
        return KOD_OK
    src = son_csv_bul(kok, ayar.cikti if False else None)
    # --cikti burada kaynak değil. Kaynak için --test-klasoru kullanılabilir diye tutmuyoruz; karışmasın.
    if not src:
        print("[HATA] Taranacak sonuç CSV bulunamadı. Önce tum_test.bat veya bellek_test.bat çalıştır.")
        return KOD_HATA
    outdir = kok / "hizli_sonuclar" / "son"
    outdir.mkdir(parents=True, exist_ok=True)
    manifest = outdir / "hatali_tekil_manifest.csv"
    rapor = outdir / "HIZLI_TARAMA_RAPORU.md"
    rows = []
    bad = []
    unique = {}
    with src.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
            st = row_get(row, "status", "durum", "sonuc", "result")
            if status_bad(st):
                path = row_get(row, "test_path", "path", "dosya", "file", "test")
                mode = row_get(row, "mode", "mod") or "compact"
                if path:
                    key = re.sub(r"^.*?uxm[\\/]tests[\\/]", "uxm/tests/", path.replace("\\", "/"))
                    unique.setdefault(key, {"test_path": path, "mode": mode, "status": st})
                    bad.append(row)
    with manifest.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["test_path", "mode", "status"])
        w.writeheader()
        for v in unique.values():
            w.writerow(v)
    rapor.write_text(
        f"# Hızlı Tarama Raporu\n\n"
        f"- Kaynak CSV: `{src}`\n"
        f"- Toplam satır: {len(rows)}\n"
        f"- Hatalı satır: {len(bad)}\n"
        f"- Tekil hatalı anahtar: {len(unique)}\n"
        f"- Manifest: `{manifest}`\n",
        encoding="utf-8"
    )
    print(f"[HIZLI_TARA] kaynak={src} total={len(rows)} hatalı_satır={len(bad)} tekil_hatalı_anahtar={len(unique)}")
    print(f"[HIZLI_TARA] manifest={manifest}")
    return KOD_OK


def placeholder_tara(ayar: Ayarlar, kesin: bool = False) -> int:
    kok = kok_bul(ayar)
    yaz_uyari(ayar)
    if ayar.help:
        print_help("placeholder_tara")
        return KOD_OK
    terms = ["placeholder", "todo", "dummy", "stub"]
    if kesin:
        terms += ["not implemented", "reserved", "pass  'todo", "return 0", "case else"]
    skip_dirs = {".git", "build", "Emekliler", "placeholder_raporu", "hizli_sonuclar", "sonuclar_bellek", "sonuclar_tum", "sonuclar_hatali"}
    files = []
    for ext in ("*.bas", "*.bi", "*.fbs", "*.py", "*.bat", "*.md", "*.json", "*.csv"):
        for p in kok.rglob(ext):
            if any(part in skip_dirs for part in p.parts):
                continue
            files.append(p)
    findings = []
    for p in files:
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for ln, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            for t in terms:
                if t in low:
                    findings.append({"dosya": str(p.relative_to(kok)), "satir": ln, "terim": t, "icerik": line[:220]})
    outdir = kok / ("placeholder_kesin_rapor" if kesin else "placeholder_raporu")
    outdir.mkdir(parents=True, exist_ok=True)
    csvp = outdir / ("placeholder_kesin_rapor.csv" if kesin else "placeholder_raporu.csv")
    mdp = outdir / ("PLACEHOLDER_KESIN_RAPORU.md" if kesin else "PLACEHOLDER_RAPORU.md")
    with csvp.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["dosya", "satir", "terim", "icerik"])
        w.writeheader(); w.writerows(findings)
    lines = ["# Placeholder Denetim Raporu", "", f"Bulgu sayısı: {len(findings)}", f"CSV: `{csvp}`", ""]
    for x in findings[:200]:
        lines.append(f"- `{x['dosya']}:{x['satir']}` **{x['terim']}** — {x['icerik']}")
    if len(findings) > 200:
        lines.append(f"\nİlk 200 bulgu gösterildi; toplam {len(findings)} bulgu var.")
    mdp.write_text("\n".join(lines), encoding="utf-8")
    print(f"[PLACEHOLDER_TARA] bulgu={len(findings)} rapor={mdp}")
    if ayar.uygula or "--hata-ver" in ayar.raw or "--fail" in ayar.raw or "--fail-on-findings" in ayar.raw:
        return KOD_BULGU if findings else KOD_OK
    return KOD_OK


def performans(ayar: Ayarlar) -> int:
    kok = kok_bul(ayar)
    out = kok / "raporlar" / "performans"
    out.mkdir(parents=True, exist_ok=True)
    md = out / f"PERFORMANS_RAPORU_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
    md.write_text(
        "# UXM Performans Raporu\n\n"
        "Bu V21 onarım paketinde performans komutu, mevcut sonuç CSV dosyalarını özetlemek için ayrılmıştır.\n"
        "Exe-only timing runner ayrı mevcutsa bu komut ona bağlanabilir.\n",
        encoding="utf-8"
    )
    print(f"[PERFORMANS] rapor={md}")
    return KOD_OK


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help", "yardim", "help"):
        print_help()
        return KOD_OK
    komut = argv[0]
    ayar = Ayarlar(argv[1:])
    if komut in ("yardim", "help"):
        print_help()
        return KOD_OK
    if komut in ("bellek", "bellek_test", "memory_test"):
        return test_kos(ayar, "bellek")
    if komut in ("tum", "tum_test", "all_test"):
        return test_kos(ayar, "tum")
    if komut in ("hatali", "hatali_test", "failed_test"):
        return test_kos(ayar, "hatali")
    if komut in ("hizli_tara", "fast_scan"):
        return hizli_tara(ayar)
    if komut in ("placeholder_tara", "placeholder_scan"):
        return placeholder_tara(ayar, kesin=False)
    if komut in ("placeholder_kapi", "placeholder_gate"):
        ayar.uygula = True
        return placeholder_tara(ayar, kesin=False)
    if komut in ("placeholder_kesin_tara", "strict_placeholder_scan"):
        return placeholder_tara(ayar, kesin=True)
    if komut in ("placeholder_kapi_sert", "strict_placeholder_gate"):
        ayar.uygula = True
        return placeholder_tara(ayar, kesin=True)
    if komut.startswith("stage"):
        # örn: stage21_placeholder, stage20
        return test_kos(ayar, komut)
    if komut in ("derleyici_derle", "build_compiler"):
        return test_kos(ayar, "bellek")
    if komut in ("performans", "performance"):
        return performans(ayar)
    print(f"[HATA] Bilinmeyen komut: {komut}")
    print_help()
    return KOD_HATA

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
