import csv
import datetime
import glob
import os
import re
import statistics
import sys
from pathlib import Path

LEGACY_HISTORY = "test_historyx.csv"
LEGACY_SUMMARY = "test_stats_summaryx.csv"
LEGACY_HEADER = ["Tarih", "Test_Adi", "Son_Sure", "Derleme_Sn"]


def parse_time(time_str):
    """Windows HH:MM:SS,cc zamanını saniyeye çevirir."""
    try:
        time_str = str(time_str).replace(',', '.').strip()
        h, m, s = time_str.split(':')
        return float(h) * 3600 + float(m) * 60 + float(s)
    except Exception:
        return 0.0


def is_legacy_row(row):
    return len(row) >= 4 and re.match(r"^\d{4}-\d{2}-\d{2}", row[0].strip())


def history_schema_ok(path):
    """Eski aktif geçmiş dosyası sadece 4 kolonlu olmalı. Karışık dosyaya ekleme yapma."""
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return True, "yeni dosya"
    with open(path, "r", encoding="utf-8-sig", errors="replace", newline="") as f:
        for row in csv.reader(f):
            if not row:
                continue
            if row == LEGACY_HEADER:
                continue
            if len(row) == 4:
                return True, "legacy 4 kolon"
            return False, f"uyumsuz kolon sayısı: {len(row)}; ilk satır={row[:5]}"
    return True, "boş/yorum"


def pick_latest_sonuc():
    nums = []
    for p in glob.glob("sonuc*.txt"):
        m = re.fullmatch(r"sonuc(\d+)\.txt", os.path.basename(p), re.IGNORECASE)
        if m:
            nums.append((os.path.getmtime(p), int(m.group(1)), p))
    if not nums:
        return None
    return max(nums)[2]


def parse_sonuc_log(log_file):
    current_results = []
    build_start = 0.0
    build_duration = 0.0
    test_starts = {}
    current_time_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    with open(log_file, "r", encoding="latin-1", errors="replace") as f:
        for line in f:
            parts = line.strip().split('@')
            if len(parts) < 2:
                continue
            tag = parts[0]
            if tag == "START_BUILD":
                build_start = parse_time(parts[1])
            elif tag == "END_BUILD":
                build_duration = parse_time(parts[1]) - build_start
                if build_duration < 0:
                    build_duration += 24 * 3600
            elif tag == "DATA_START" and len(parts) >= 3:
                test_starts[parts[1]] = parse_time(parts[2])
            elif tag == "DATA_END" and len(parts) >= 3:
                name = parts[1]
                duration = parse_time(parts[2]) - test_starts.get(name, parse_time(parts[2]))
                if duration < 0:
                    duration += 24 * 3600
                current_results.append([current_time_str, name, f"{duration:.4f}", f"{build_duration:.4f}"])
    return current_results


def load_legacy_history(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, "r", encoding="utf-8-sig", errors="replace", newline="") as f:
        for row in csv.reader(f):
            if not row or row == LEGACY_HEADER:
                continue
            if is_legacy_row(row):
                rows.append(row[:4])
    return rows


def write_summary(history_rows, summary_file):
    groups = {}
    for row in history_rows:
        test = row[1].strip()
        try:
            dur = float(row[2].replace(',', '.'))
        except Exception:
            continue
        groups.setdefault(test, []).append(dur)

    with open(summary_file, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Test_Adi", "Calistirma_Sayisi", "Ortalama_Sure", "Median_Sure", "Min_Sure", "Max_Sure", "Son_Sure", "Std_Sapma"])
        for test, vals in sorted(groups.items()):
            w.writerow([
                test,
                len(vals),
                f"{statistics.mean(vals):.4f}",
                f"{statistics.median(vals):.4f}",
                f"{min(vals):.4f}",
                f"{max(vals):.4f}",
                f"{vals[-1]:.4f}",
                f"{statistics.stdev(vals):.4f}" if len(vals) > 1 else "0.0000",
            ])


def run_analysis():
    log_file = sys.argv[1] if len(sys.argv) > 1 else pick_latest_sonuc()
    if not log_file:
        print("Hata: sonucN.txt bulunamadı!")
        return 1

    ok, note = history_schema_ok(LEGACY_HISTORY)
    if not ok:
        print("[DURDURULDU] test_history.csv karışık/uyumsuz görünüyor.")
        print("Sebep:", note)
        print("Önce recovered_data/test_history.csv dosyasını ana klasöre kopyala veya bozuk dosyayı emekliye al.")
        return 2

    print(f"Analiz ediliyor: {log_file}")
    current_results = parse_sonuc_log(log_file)
    if not current_results:
        print("Hata: İşlenecek DATA_START/DATA_END verisi bulunamadı!")
        return 1

    with open(LEGACY_HISTORY, "a", encoding="utf-8-sig", newline="") as f:
        csv.writer(f).writerows(current_results)

    all_rows = load_legacy_history(LEGACY_HISTORY)
    write_summary(all_rows, LEGACY_SUMMARY)
    print(f"--- ANALİZ BİTTİ ---")
    print(f"Log          : {log_file}")
    print(f"Eklenen test : {len(current_results)}")
    print(f"Geçmiş       : {LEGACY_HISTORY} / 4 kolon legacy format")
    print(f"Özet         : {LEGACY_SUMMARY}")
    return 0


if __name__ == "__main__":
    raise SystemExit(run_analysis())
