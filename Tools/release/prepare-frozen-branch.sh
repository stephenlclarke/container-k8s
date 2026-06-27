#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

readme = Path("README.md")
lines = readme.read_text(encoding="utf-8").splitlines()
filtered = [
    line
    for line in lines
    if "sonarcloud.io/api/project_badges" not in line
    and "sonarcloud.io/summary/new_code" not in line
]
readme.write_text("\n".join(filtered) + "\n", encoding="utf-8")
PY
