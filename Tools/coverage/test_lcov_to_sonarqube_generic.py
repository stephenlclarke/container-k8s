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

"""Unit tests for LCOV to SonarQube generic coverage conversion."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


def load_lcov_module():
    """Load lcov-to-sonarqube-generic.py despite its CLI-oriented filename."""
    module_path = Path(__file__).with_name("lcov-to-sonarqube-generic.py")
    spec = importlib.util.spec_from_file_location("lcov_to_sonarqube_generic", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


lcov = load_lcov_module()


class LcovToSonarQubeGenericTests(unittest.TestCase):
    """Coverage converter behavior used by local CI and SonarCloud scans."""

    def test_parse_lcov_keeps_project_relative_sources(self) -> None:
        """LCOV records outside the project root are omitted from the XML input."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            outside_source = root.parent / f"{root.name}-outside" / "Secret.swift"
            report = root / "coverage.lcov"
            report.write_text(
                f"""
                SF:{root}/Sources/K8sCore/BuildInfo.swift
                DA:1,1
                DA:2,0
                end_of_record
                SF:{outside_source}
                DA:1,1
                end_of_record
                SF:Sources/K8sCLI/Main.swift
                DA:3,1
                end_of_record
                """,
                encoding="utf-8",
            )

            files = lcov.parse_lcov(report, root)

            self.assertEqual(
                files,
                {
                    "Sources/K8sCLI/Main.swift": {3: True},
                    "Sources/K8sCore/BuildInfo.swift": {1: True, 2: False},
                },
            )

    def test_project_path_argument_rejects_parent_escape(self) -> None:
        """CLI path arguments must stay inside the configured project root."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()

            with self.assertRaises(ValueError):
                lcov.project_path_argument("../coverage.lcov", root, must_exist=False)

    def test_project_path_argument_accepts_root_file(self) -> None:
        """A real report path under the project root is accepted."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            report = root / "coverage.lcov"
            report.write_text("TN:\n", encoding="utf-8")

            self.assertEqual(lcov.project_path_argument("coverage.lcov", root, must_exist=True), report)


if __name__ == "__main__":
    unittest.main()
