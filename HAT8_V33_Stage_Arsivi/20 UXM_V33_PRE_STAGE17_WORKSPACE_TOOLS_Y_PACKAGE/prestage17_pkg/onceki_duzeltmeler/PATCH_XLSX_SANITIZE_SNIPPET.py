# UXM_STAGE_RUNNER.py icin XLSX/CSV guvenli hucre temizleme notu.
# Kontrol karakterleri Excel/openpyxl tarafinda IllegalCharacterError uretebilir.
import re
ILLEGAL_XLSX_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")

def ux_excel_safe(value):
    if value is None:
        return ""
    if isinstance(value, (int, float, bool)):
        return value
    return ILLEGAL_XLSX_CHARS_RE.sub(lambda m: "\\x%02X" % ord(m.group(0)), str(value))

# ws.append(row) yerine:
# ws.append([ux_excel_safe(col) for col in row])
