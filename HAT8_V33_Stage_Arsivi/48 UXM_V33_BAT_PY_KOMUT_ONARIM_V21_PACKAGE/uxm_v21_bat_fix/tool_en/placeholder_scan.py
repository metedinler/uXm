# -*- coding: utf-8 -*-
from __future__ import annotations
import sys
from pathlib import Path

# Uyumluluk dosyası: eski batlar placeholder_tara.py çağırıyordu.
# Artık gerçek iş uxm_komut_merkezi.py içindedir.
if __name__ == '__main__':
    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    import uxm_komut_merkezi as m
    args = ['placeholder_tara'] + sys.argv[1:]
    # Eski --hata-ver / --fail-on-findings aliasları korunur.
    if '--hata-ver' in sys.argv[1:] or '--fail' in sys.argv[1:] or '--fail-on-findings' in sys.argv[1:]:
        args = ['placeholder_kapi'] + [a for a in sys.argv[1:] if a not in ('--hata-ver','--fail','--fail-on-findings')]
    raise SystemExit(m.main(args))
