# Building container-k8s

This guide is for contributors who need to build, test, and package `container-k8s` from source. Installation steps live in [INSTALL.md](INSTALL.md); branch rules live in [BRANCHES.md](BRANCHES.md).

## Requirements

- macOS with an Apple Swift 6.2 or newer toolchain.
- The [`apple/container`](https://github.com/apple/container) source checkout as a sibling directory when working on runtime integration.
- Python 3 for packaging metadata and release helpers.
- Node.js with npm for the required Markdown lint step:

  ```sh
  npm install --global markdownlint-cli@0.48.0
  ```

- Optional: `sonar-scanner` and either `SONAR_TOKEN` or `SONAR_TOKEN_PERSONAL` for local SonarCloud scans.

If you need to force a specific Apple developer directory, set:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Checkout Layout

Clone [`apple/container`](https://github.com/apple/container) and `container-k8s` as sibling directories:

```sh
mkdir -p ~/github
git clone https://github.com/apple/container.git ~/github/container
git clone https://github.com/stephenlclarke/container-k8s.git ~/github/container-k8s
cd ~/github/container-k8s
```

The resulting layout should be:

```text
~/github/container
~/github/container-k8s
```

## Build

Build the Swift plugin executable:

```sh
make build
```

Build a release executable:

```sh
make build-release
```

Run the plugin from source:

```sh
swift run k8s version
swift run k8s run demo --dry-run
```

## Test And Validate

Run the default validation workflow:

```sh
make ci
```

`make ci` runs coverage-tool unit tests, Markdown linting, Homebrew formula Ruby syntax checks, Swift tests with coverage instrumentation, the coverage threshold gate, the debug build, and a CLI smoke test.

Run faster local checks with:

```sh
make check
```

Run tests directly with:

```sh
make test
```

Generate Swift coverage reports and enforce the minimum coverage threshold:

```sh
make coverage-check
```

The default threshold is 80 percent. Override it locally with:

```sh
COVERAGE_MIN=90 make coverage-check
```

Generated coverage reports are:

```text
coverage.lcov
coverage.xml
```

`coverage.xml` uses the SonarQube generic coverage format and is referenced by `sonar-project.properties`.

Run the CLI smoke test against an already built debug executable:

```sh
make cli-smoke-built
```

## Package

Build a debug plugin archive:

```sh
make package-debug
```

Build a release plugin archive:

```sh
make package-release
```

The archive layout is:

```text
k8s/bin/k8s
k8s/config.toml
k8s/resources/build-info.json
```

`build-info.json` records the version, source, branch, lane, commit, build type, and `APPLE_CONTAINER_REF` pin. Installed plugins surface this data through:

```sh
container k8s version
container k8s version --format json
```

## GitHub Actions

The workflow layout mirrors `container-compose`:

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `CI` | Pushes to `main`, `release/*`, `snapshot/*`, PRs to `main`, and manual runs | Runs local validation. Frozen branches run package validation for the matching lane. |
| `Quality` | Pushes and PRs, with scheduled TSan | Runs sanitizer and Swift style advisory checks. |
| `CodeQL` | Pushes to `main`, PRs to `main`, weekly schedule, and manual runs | Runs CodeQL over Swift sources. |
| `Homebrew` | Pushes, PRs, and manual runs | Validates the Homebrew formula syntax and tap inspection. |
| `Prebuilt Binaries` | Pushes to `release/*` or `snapshot/*`, and manual runs | Publishes branch-specific release assets and updates `stephenlclarke/homebrew-tap`. |

SonarCloud analysis is wired into CI and skips cleanly until a repository secret is configured.
