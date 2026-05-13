# -*- coding: utf-8 -*-
from __future__ import annotations
import sys
from pathlib import Path

EN_HELP = """
UX-MINIMA x64 Command Help
==========================
Usage:
  <command>.bat [options]

Options:
  -h,        --help                         Shows this help screen.
  -k,        --root <path>                  Project root directory. Example: -k C:\\UXMv33
  -d,        --no-build                     Runs tests without rebuilding the compiler.
  -D,        --stop-on-fail                 Stops at first failure.
  -n,        --limit <number>               Limits the number of tests.
  -s,        --from-index <number>          Starts from this test index.
  -a,        --name-contains <text>         Selects tests by name substring.
  -z,        --timeout-test <seconds>       Per-test timeout.
  -t,        --test-dir <path>              Test directory.
  -c,        --out <path>                   Output/report directory.
  -u,        --apply                        Applies changes.
  -b,        --retire-build                 Retires build folders.

Important:
  Do not write 'cd' inside command options.
  Wrong:  .\\stage21_placeholder_test.bat -k cd C:\\UXMv33
  Right:  cd C:\\UXMv33
          .\\stage21_placeholder_test.bat -d
""".strip()

if __name__ == "__main__":
    if not sys.argv[1:] or any(x in sys.argv[1:] for x in ("-h", "--help", "help")):
        print(EN_HELP)
        raise SystemExit(0)
    tr_dir = Path(__file__).resolve().parents[1] / "araclar"
    sys.path.insert(0, str(tr_dir))
    import uxm_komut_merkezi as tr
    raise SystemExit(tr.main(sys.argv[1:]))
