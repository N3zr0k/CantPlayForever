#!/usr/bin/env python3
"""Baut <Repo>_Repo_<Version>.zip: ein Wurzelordner, kein .git."""
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP = {'.git', '__pycache__', '.pytest_cache'}


def main():
    if len(sys.argv) != 2:
        print('Aufruf: build_repo_zip.py <Version>')
        return 2
    out = ROOT.parent / f'{ROOT.name}_Repo_{sys.argv[1]}.zip'
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(ROOT.rglob('*')):
            rel = path.relative_to(ROOT)
            if path.is_file() and not SKIP & set(rel.parts):
                z.write(path, f'{ROOT.name}/{rel.as_posix()}')
    print(out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
