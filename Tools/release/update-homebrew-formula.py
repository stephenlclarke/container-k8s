#!/usr/bin/env python3
import argparse
from pathlib import Path


def replace_line(lines: list[str], prefix: str, replacement: str) -> list[str]:
    return [replacement if line.lstrip().startswith(prefix) else line for line in lines]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--formula", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--asset", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--sha256", required=True)
    args = parser.parse_args()

    path = Path(args.formula)
    lines = path.read_text(encoding="utf-8").splitlines()
    lines = replace_line(lines, "url ", f'  url "{args.url}"')
    lines = replace_line(lines, "sha256 ", f'  sha256 "{args.sha256}"')
    lines = replace_line(lines, "version ", f'  version "{args.version}"')

    updated: list[str] = []
    skip_next_asset = False
    for line in lines:
        if "This formula installs the " in line and " prebuilt release asset:" in line:
            updated.append(f"      This formula installs the {args.label} prebuilt release asset:")
            skip_next_asset = True
            continue
        if skip_next_asset:
            updated.append(f"        {args.asset}")
            skip_next_asset = False
            continue
        updated.append(line)

    path.write_text("\n".join(updated) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
