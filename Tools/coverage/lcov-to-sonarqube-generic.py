#!/usr/bin/env python3
##===----------------------------------------------------------------------===##
## Copyright 2026 container-k8s project authors.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   https://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##===----------------------------------------------------------------------===##

"""Convert LCOV line coverage into SonarQube generic coverage XML."""

import posixpath
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def usage() -> None:
    """Print command usage for invalid invocations."""
    print("usage: lcov-to-sonarqube-generic.py <input.lcov> <output.xml> [project-root]", file=sys.stderr)


def project_path_argument(argument: str, root: Path, must_exist: bool) -> Path:
    """Return a CLI path only after proving it remains inside the project root."""
    raw_path = Path(argument)
    candidate = raw_path if raw_path.is_absolute() else root / raw_path
    resolved = candidate.resolve(strict=must_exist)
    resolved.relative_to(root)
    if must_exist and not resolved.is_file():
        raise ValueError(f"expected a file inside project root: {argument}")
    return resolved


def clean_relative_path(path: str) -> str | None:
    """Normalize and reject coverage paths that escape the project."""
    normalized = posixpath.normpath(path.replace("\\", "/"))
    if normalized in ("", ".") or normalized == ".." or normalized.startswith("../") or normalized.startswith("/"):
        return None
    return normalized


def relative_path(path: str, root: Path) -> str | None:
    """Return a Sonar-friendly path relative to the project when possible."""
    root_prefix = root.as_posix().rstrip("/") + "/"
    source = path.strip().replace("\\", "/")
    if source.startswith(root_prefix):
        return clean_relative_path(source[len(root_prefix) :])
    if source.startswith("/"):
        return None
    return clean_relative_path(source)


def parse_lcov(path: Path, root: Path) -> dict[str, dict[int, bool]]:
    """Parse LCOV records into per-file covered line maps."""
    files: dict[str, dict[int, bool]] = {}
    current: str | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("SF:"):
            current = relative_path(line[3:], root)
            if current is not None:
                files.setdefault(current, {})
            continue
        if line.startswith("DA:") and current is not None:
            line_number_text, count_text, *_ = line[3:].split(",")
            files[current][int(line_number_text)] = int(count_text) > 0
            continue
        if line == "end_of_record":
            current = None

    return files


def write_generic_coverage(files: dict[str, dict[int, bool]], output: Path) -> None:
    """Write SonarQube generic coverage XML from parsed line coverage."""
    coverage = ET.Element("coverage", version="1")
    for file_path in sorted(files):
        file_element = ET.SubElement(coverage, "file", path=file_path)
        for line_number in sorted(files[file_path]):
            ET.SubElement(
                file_element,
                "lineToCover",
                lineNumber=str(line_number),
                covered=str(files[file_path][line_number]).lower(),
            )

    tree = ET.ElementTree(coverage)
    ET.indent(tree, space="  ")
    tree.write(output, encoding="utf-8", xml_declaration=True)


def main() -> int:
    """Convert the input LCOV file to SonarQube generic coverage XML."""
    if len(sys.argv) not in (3, 4):
        usage()
        return 2

    root = Path(sys.argv[3] if len(sys.argv) == 4 else ".").resolve()
    try:
        input_path = project_path_argument(sys.argv[1], root, must_exist=True)
        output_path = project_path_argument(sys.argv[2], root, must_exist=False)
        files = parse_lcov(input_path, root)
        write_generic_coverage(files, output_path)
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
