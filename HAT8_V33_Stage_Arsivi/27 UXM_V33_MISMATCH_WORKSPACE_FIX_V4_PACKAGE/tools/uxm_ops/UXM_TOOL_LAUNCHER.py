#!/usr/bin/env python3
import argparse, subprocess, sys, tempfile, shutil
from pathlib import Path
TOOLS={
 'fix_mismatch':'tools/uxm_ops/UXM_FIX_KNOWN_MISMATCHES_V4.py',
 'diag_mismatch':'tools/uxm_ops/UXM_MISMATCH_DIAGNOSER_V4.py',
 'workspace':'tools/uxm_ops/UXM_WORKSPACE_ORGANIZER_V4.py',
 'emekli':'tools/uxm_ops/UXM_EMEKLI_BUILD_ANALYZER_V4.py',
}

def main():
 ap=argparse.ArgumentParser()
 ap.add_argument('--tool', required=True, choices=TOOLS)
 ap.add_argument('args', nargs=argparse.REMAINDER)
 ns=ap.parse_args()
 root=Path.cwd(); src=root/TOOLS[ns.tool]
 if not src.exists():
  print('Tool bulunamadi:',src); return 2
 tmp=root/'_uxm_active_tool_tmp.py'
 shutil.copy2(src,tmp)
 try:
  cmd=[sys.executable,str(tmp)] + ns.args
  return subprocess.call(cmd)
 finally:
  try: tmp.unlink()
  except OSError: pass
if __name__=='__main__': raise SystemExit(main())
