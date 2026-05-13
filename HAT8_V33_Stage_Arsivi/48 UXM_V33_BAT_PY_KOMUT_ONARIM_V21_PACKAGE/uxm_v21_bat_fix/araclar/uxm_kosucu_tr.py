# -*- coding: utf-8 -*-
"""Uyumluluk sarmalı: V11/V12 paketlerindeki uxm_kosucu_tr.py çağrılarını kırmamak için."""
from __future__ import annotations
import sys
from pathlib import Path

if __name__ == '__main__':
    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    import uxm_komut_merkezi as m
    raise SystemExit(m.main(['stage_test'] + sys.argv[1:]))
