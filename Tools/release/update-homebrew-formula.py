#!/usr/bin/env python3
import argparse
from pathlib import Path

FORMULA_DIR = Path("homebrew-tap") / "Formula"
FORMULA_PATHS = {
    "container-k8s.rb": FORMULA_DIR / "container-k8s.rb",
}


def replace_line(lines: list[str], prefix: str, replacement: str) -> list[str]:
    return [replacement if line.lstrip().startswith(prefix) else line for line in lines]


def formula_path(formula: str) -> Path:
    try:
        path = FORMULA_PATHS[formula].resolve()
    except KeyError as error:
        allowed = ", ".join(sorted(FORMULA_PATHS))
        raise ValueError(f"unsupported formula {formula!r}; expected one of: {allowed}") from error
    path.relative_to(FORMULA_DIR.resolve())
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--formula", required=True, choices=sorted(FORMULA_PATHS))
    parser.add_argument("--url", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--asset", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--sha256", required=True)
    args = parser.parse_args()

    path = formula_path(args.formula)
    lines = path.read_text(encoding="utf-8").splitlines()
    lines = replace_line(lines, "url ", f'  url "{args.url}"')
    lines = replace_line(lines, "sha256 ", f'  sha256 "{args.sha256}"')
    lines = replace_line(lines, "version ", f'  version "{args.version}"')

    updated: list[str] = []
    skip_next_asset = False
    for line in lines:
        if "This formula installs the " in line and " prebuilt package asset:" in line:
            updated.append(f"      This formula installs the {args.label} prebuilt package asset:")
            skip_next_asset = True
            continue
        if skip_next_asset:
            updated.append(f"        {args.asset}")
            skip_next_asset = False
            continue
        updated.append(line)

    with path.open("w", encoding="utf-8") as formula_file:
        formula_file.write("\n".join(updated) + "\n")


if __name__ == "__main__":
    main()
