# -*- coding: utf-8 -*-
"""Uyumluluk sarmalı: eski .bat dosyaları bu adı çağırıyordu."""
from __future__ import annotations
import sys
from pathlib import Path

if __name__ == '__main__':
    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    import uxm_komut_merkezi as m
    # Eski çağrı parametrelerini mümkün olduğunca stage_test'e çevir.
    args = sys.argv[1:]
    # --test-klasoru varsa genel test çalıştır.
    if '--test-klasoru' in args or '--test-dir' in args:
        raise SystemExit(m.main(['stage_test'] + args))
    raise SystemExit(m.main(['yardim'] + args))
