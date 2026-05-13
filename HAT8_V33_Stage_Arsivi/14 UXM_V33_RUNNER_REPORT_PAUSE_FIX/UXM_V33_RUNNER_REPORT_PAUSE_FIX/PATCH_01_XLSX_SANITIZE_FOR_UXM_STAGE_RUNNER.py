# UXM_STAGE_RUNNER.py icin hedefli hotfix
# Amaç: testler BASARILI olduktan sonra XLSX raporu yazilirken openpyxl IllegalCharacterError vermesini engellemek.
# Sebep: UXM test ciktilarinda \x00B, \x01B gibi kontrol karakterleri olabiliyor.
# Raw log aynen korunur; CSV/XLSX icin kontrol karakterleri gorunur metne cevrilir.

import re

# Excel XML icinde yasak kontrol karakterleri:
# TAB(\x09), LF(\x0A), CR(\x0D) serbest; diger C0 kontroller yasak.
_ILLEGAL_XLSX_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")


def ux_excel_safe(value):
    """Excel hucrelerine yazmadan once degeri guvenli hale getirir."""
    if value is None:
        return ""
    if isinstance(value, (int, float, bool)):
        return value
    s = str(value)
    # Kontrol karakterini silmek yerine \x00 biciminde gorunur yapıyoruz.
    return _ILLEGAL_XLSX_CHARS_RE.sub(lambda m: "\\x%02X" % ord(m.group(0)), s)


def ux_csv_safe(value):
    """CSV/summary icin de ayni guvenli metin cikisi."""
    return ux_excel_safe(value)


# UXM_STAGE_RUNNER.py icinde try_write_xlsx fonksiyonundaki su satiri:
#     ws.append(row)
# bununla degistir:
#     ws.append([ux_excel_safe(col) for col in row])

# Daha saglam surum:
def append_excel_row_safe(ws, row):
    ws.append([ux_excel_safe(col) for col in row])


# try_write_xlsx icine en guvenli kullanim ornegi:
"""
def try_write_xlsx(self, current_csv, summary_path, xlsx_path):
    try:
        from openpyxl import Workbook
        wb = Workbook()
        ws = wb.active
        ws.title = "UXM_Test_Results"
        with open(current_csv, "r", encoding="utf-8-sig", newline="") as f:
            import csv
            reader = csv.reader(f)
            for row in reader:
                ws.append([ux_excel_safe(col) for col in row])
        wb.save(xlsx_path)
        return True
    except Exception as exc:
        # XLSX raporu hata verse bile 104/104 BASARILI test sonucunu bozmamali.
        warn_path = str(xlsx_path) + ".xlsx_error.txt"
        with open(warn_path, "w", encoding="utf-8") as w:
            w.write("XLSX raporu yazilamadi. Test sonuclari gecersiz sayilmadi.\n")
            w.write(repr(exc) + "\n")
        return False
"""
