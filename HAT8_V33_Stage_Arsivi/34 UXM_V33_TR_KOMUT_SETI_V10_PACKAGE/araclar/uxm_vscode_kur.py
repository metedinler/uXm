# -*- coding: utf-8 -*-
from pathlib import Path
import shutil, os
root=Path(__file__).resolve().parents[1]
src=root/'vscode'/'uxm-turkce'
dst=Path.home()/'.vscode'/'extensions'/'metedinler.uxm-turkce-v10'
if not src.exists():
    print('VSCode eklenti kaynağı bulunamadı:',src); raise SystemExit(1)
if dst.exists(): shutil.rmtree(dst)
shutil.copytree(src,dst)
print('UXM Türkçe VSCode eklentisi kuruldu:',dst)
print('VSCode açıksa yeniden yükle: Ctrl+Shift+P -> Developer: Reload Window')
