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
DIST_DIR ?= dist
PLUGIN_ARCHIVE ?= container-k8s-plugin.tar.gz
K8S_VERSION ?= 0.1.0
CONTAINER_K8S_BRANCH ?= $(shell git branch --show-current 2>/dev/null || git rev-parse --short HEAD)
CONTAINER_K8S_LANE ?= $(shell $(PYTHON) -c 'branch = "$(CONTAINER_K8S_BRANCH)"; print("main" if branch == "main" else "release" if branch.startswith("release/") else "snapshot" if branch.startswith("snapshot/") else "detached" if branch in ("", "HEAD") else "development")')
CONTAINER_K8S_COMMIT ?= $(shell git rev-parse --verify HEAD 2>/dev/null || printf 'unspecified')
CONTAINER_K8S_SOURCE ?= $(shell $(PYTHON) -c 'import subprocess; result = subprocess.run(["git", "remote", "get-url", "origin"], capture_output=True, text=True); url = result.stdout.strip() if result.returncode == 0 else ""; url = url[len("git@github.com:"):] if url.startswith("git@github.com:") else url; url = url[len("https://github.com/"):] if url.startswith("https://github.com/") else url; url = url[:-4] if url.endswith(".git") else url; print(url or "unspecified")')
CONTAINER_REF ?= $(shell sed -n '1{s/[[:space:]]//g;p;q;}' APPLE_CONTAINER_REF 2>/dev/null || printf 'unspecified')
MARKDOWN_FILES := README.md BUILD.md BRANCHES.md CODE_OF_CONDUCT.md CONTRIBUTING.md DESIGN.md INSTALL.md PLAN.md SECURITY.md STATUS.md SUPPORT.md .github/pull_request_template.md

.PHONY: all workflow ci check lint format fmt resolve build build-release run test coverage-check cli-smoke cli-smoke-built package package-release package-debug package-built clean sonar-scan

all: workflow

workflow: ci package

ci: check test coverage-check build cli-smoke-built

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

coverage-check: test
	@printf 'coverage threshold gate is not enabled until Swift coverage export lands\n'

lint:
	$(MARKDOWNLINT) $(MARKDOWN_FILES)
	ruby -c Formula/container-k8s.rb
	ruby -c Formula/container-k8s-snapshot.rb

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

package: package-debug

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
	@test -n "$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}" || { \
		printf 'SONAR_TOKEN or SONAR_TOKEN_PERSONAL is required for sonar-scan\n' >&2; \
		exit 2; \
	}
	sonar-scanner

clean:
	rm -rf .build .swiftpm "$(DIST_DIR)" "$(PLUGIN_ARCHIVE)" "$(PLUGIN_ARCHIVE).sha256" coverage.lcov coverage.xml
