#===----------------------------------------------------------------------===#
# Copyright 2026 container-k8s project authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#===----------------------------------------------------------------------===#

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := all

SWIFT ?= swift
PYTHON ?= python3
MARKDOWNLINT ?= markdownlint
COVERAGE_MIN ?= 80
DIST_DIR ?= dist
PLUGIN_ARCHIVE ?= container-k8s-plugin.tar.gz
K8S_VERSION ?= 0.1.0
CONTAINER_K8S_BRANCH ?= $(shell git branch --show-current 2>/dev/null || git rev-parse --short HEAD)
CONTAINER_K8S_LANE ?= $(shell $(PYTHON) -c 'branch = "$(CONTAINER_K8S_BRANCH)"; print("main" if branch == "main" else "detached" if branch in ("", "HEAD") else "development")')
CONTAINER_K8S_COMMIT ?= $(shell git rev-parse --verify HEAD 2>/dev/null || printf 'unspecified')
CONTAINER_K8S_SOURCE ?= $(shell $(PYTHON) -c 'import subprocess; result = subprocess.run(["git", "remote", "get-url", "origin"], capture_output=True, text=True); url = result.stdout.strip() if result.returncode == 0 else ""; url = url[len("git@github.com:"):] if url.startswith("git@github.com:") else url; url = url[len("https://github.com/"):] if url.startswith("https://github.com/") else url; url = url[:-4] if url.endswith(".git") else url; print(url or "unspecified")')
CONTAINER_REF ?= $(shell sed -n '1{s/[[:space:]]//g;p;q;}' APPLE_CONTAINER_REF 2>/dev/null || printf 'unspecified')
MARKDOWN_FILES := README.md BUILD.md BRANCHES.md CODE_OF_CONDUCT.md CONTRIBUTING.md DESIGN.md INSTALL.md PLAN.md SECURITY.md STATUS.md SUPPORT.md .github/pull_request_template.md
SWIFT_RUNTIME_RESOURCE_PATH ?= $(shell $(SWIFT) -print-target-info 2>/dev/null | $(PYTHON) -c 'import json, sys; print(json.load(sys.stdin).get("paths", {}).get("runtimeResourcePath", ""))' 2>/dev/null || true)
SWIFT_TOOLCHAIN_USR_DIR := $(patsubst %/lib/swift,%,$(SWIFT_RUNTIME_RESOURCE_PATH))
SWIFT_LLVM_COV ?= $(firstword $(wildcard $(SWIFT_TOOLCHAIN_USR_DIR)/bin/llvm-cov) $(shell xcrun --find llvm-cov 2>/dev/null || command -v llvm-cov 2>/dev/null || true))
SWIFT_LLVM_PROFDATA ?= $(firstword $(wildcard $(SWIFT_TOOLCHAIN_USR_DIR)/bin/llvm-profdata) $(shell xcrun --find llvm-profdata 2>/dev/null || command -v llvm-profdata 2>/dev/null || true))

.PHONY: all workflow ci check lint format fmt resolve build build-release run test swift-coverage coverage coverage-check coverage-tools-test cli-smoke cli-smoke-built package package-release package-debug package-built clean sonar-scan

all: workflow

workflow: ci package

ci: check coverage-check build cli-smoke-built

resolve:
	$(SWIFT) package resolve

build:
	$(SWIFT) build --product k8s

build-release:
	$(SWIFT) build -c release --product k8s

run:
	$(SWIFT) run k8s version

test:
	$(SWIFT) test

swift-coverage:
	@if [[ -z "$(SWIFT_LLVM_COV)" ]]; then \
		printf 'llvm-cov is required; install the active Swift toolchain or set SWIFT_LLVM_COV=/path/to/llvm-cov\n' >&2; \
		exit 1; \
	fi
	@if [[ -z "$(SWIFT_LLVM_PROFDATA)" ]]; then \
		printf 'llvm-profdata is required; install the active Swift toolchain or set SWIFT_LLVM_PROFDATA=/path/to/llvm-profdata\n' >&2; \
		exit 1; \
	fi
	@rm -f .build/*/debug/codecov/*.profraw .build/*/debug/codecov/*.profdata .build/codecov/fallback.profdata coverage.lcov coverage.xml
	$(SWIFT) test --enable-code-coverage
	test_binary="$$(find .build -path '*.xctest/Contents/MacOS/container-k8sPackageTests' -type f | head -n 1)"; \
	profile=".build/codecov/fallback.profdata"; \
	if [[ -z "$$test_binary" ]]; then \
		printf 'Swift test binary is missing; run swift test --enable-code-coverage before exporting coverage\n' >&2; \
		exit 2; \
	fi; \
	raw_profile_count="$$(find .build -name '*.profraw' -type f | wc -l | tr -d ' ')"; \
	if [[ "$$raw_profile_count" -eq 0 ]]; then \
		printf 'Swift coverage profile is missing and no raw .profraw files were found\n' >&2; \
		exit 2; \
	fi; \
	mkdir -p .build/codecov; \
	find .build -name '*.profraw' -type f -print0 | xargs -0 "$(SWIFT_LLVM_PROFDATA)" merge -sparse -o "$$profile"; \
	"$(SWIFT_LLVM_COV)" export \
		-format=lcov \
		-instr-profile="$$profile" \
		"$$test_binary" \
		--sources Sources/K8sCore \
		> coverage.lcov; \
	$(PYTHON) Tools/coverage/lcov-to-sonarqube-generic.py coverage.lcov coverage.xml .

coverage: swift-coverage

coverage-check: coverage
	$(PYTHON) Tools/coverage/check-coverage.py --minimum "$(COVERAGE_MIN)" --swift coverage.xml

coverage-tools-test:
	$(PYTHON) -m py_compile Tools/coverage/*.py Tools/release/*.py
	$(PYTHON) -m unittest discover Tools/coverage

lint: coverage-tools-test
	$(MARKDOWNLINT) $(MARKDOWN_FILES)
	ruby -c Formula/container-k8s.rb

check: lint

format fmt:
	@printf 'No automatic formatter is configured yet; run swift-format once a repo config lands.\n'

cli-smoke: build cli-smoke-built

cli-smoke-built:
	@test -x .build/debug/k8s || { \
		printf '.build/debug/k8s is missing; run make build before make cli-smoke-built\n' >&2; \
		exit 2; \
	}
	.build/debug/k8s version --short >/dev/null
	.build/debug/k8s version --format json >/dev/null
	.build/debug/k8s run demo --dry-run >/dev/null
	.build/debug/k8s load-image demo my-app:latest --dry-run >/dev/null

package: package-release

package-release: build-release
	$(MAKE) package-built BUILD_CONFIGURATION=release BUILD_PRODUCT=.build/release/k8s BUILD_TYPE=release

package-debug: build
	$(MAKE) package-built BUILD_CONFIGURATION=debug BUILD_PRODUCT=.build/debug/k8s BUILD_TYPE=debug

package-built:
	@test -x "$(BUILD_PRODUCT)" || { \
		printf 'Expected built plugin at %s\n' "$(BUILD_PRODUCT)" >&2; \
		exit 2; \
	}
	@rm -rf "$(DIST_DIR)"
	@mkdir -p "$(DIST_DIR)/k8s/bin" "$(DIST_DIR)/k8s/resources"
	cp "$(BUILD_PRODUCT)" "$(DIST_DIR)/k8s/bin/k8s"
	cp config.toml "$(DIST_DIR)/k8s/config.toml"
	$(PYTHON) -c 'import json, os; data = {"version": os.environ.get("K8S_VERSION", "$(K8S_VERSION)"), "source": os.environ.get("CONTAINER_K8S_SOURCE", "$(CONTAINER_K8S_SOURCE)"), "branch": os.environ.get("CONTAINER_K8S_BRANCH", "$(CONTAINER_K8S_BRANCH)"), "lane": os.environ.get("CONTAINER_K8S_LANE", "$(CONTAINER_K8S_LANE)"), "commit": os.environ.get("CONTAINER_K8S_COMMIT", "$(CONTAINER_K8S_COMMIT)"), "buildType": os.environ.get("BUILD_TYPE", "$(BUILD_TYPE)"), "containerRef": os.environ.get("CONTAINER_REF", "$(CONTAINER_REF)")}; open("$(DIST_DIR)/k8s/resources/build-info.json", "w", encoding="utf-8").write(json.dumps(data, sort_keys=True) + "\n")'
	tar -C "$(DIST_DIR)" -czf "$(PLUGIN_ARCHIVE)" k8s
	shasum -a 256 "$(PLUGIN_ARCHIVE)" > "$(PLUGIN_ARCHIVE).sha256"

sonar-scan:
	@test -f coverage.xml || { \
		printf 'coverage.xml is missing; run make coverage or make ci before make sonar-scan\n' >&2; \
		exit 2; \
	}
	@test -n "$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}" || { \
		printf 'SONAR_TOKEN or SONAR_TOKEN_PERSONAL is required for sonar-scan\n' >&2; \
		exit 2; \
	}
	sonar-scanner

clean:
	rm -rf .build .swiftpm "$(DIST_DIR)" "$(PLUGIN_ARCHIVE)" "$(PLUGIN_ARCHIVE).sha256" .scannerwork coverage.lcov coverage.xml
