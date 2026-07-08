# container-k8s

[![CI](https://github.com/stephenlclarke/container-k8s/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/stephenlclarke/container-k8s/actions/workflows/ci.yml?query=branch%3Amain)
[![Quality](https://github.com/stephenlclarke/container-k8s/actions/workflows/quality.yml/badge.svg?branch=main)](https://github.com/stephenlclarke/container-k8s/actions/workflows/quality.yml?query=branch%3Amain)
[![Homebrew](https://github.com/stephenlclarke/container-k8s/actions/workflows/homebrew.yml/badge.svg?branch=main)](https://github.com/stephenlclarke/container-k8s/actions/workflows/homebrew.yml?query=branch%3Amain)
[![Prebuilt Binaries](https://github.com/stephenlclarke/container-k8s/actions/workflows/prebuilt-binaries.yml/badge.svg)](https://github.com/stephenlclarke/container-k8s/actions/workflows/prebuilt-binaries.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=bugs)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=coverage)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=sqale_index)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_container-k8s&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_container-k8s)
[![CodeQL](https://github.com/stephenlclarke/container-k8s/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/stephenlclarke/container-k8s/actions/workflows/codeql.yml?query=branch%3Amain)
![Repo Visitors](https://visitor-badge.laobi.icu/badge?page_id=stephenlclarke.container-k8s)

`container-k8s` is a standalone plugin scaffold for Kubernetes development cluster workflows on Apple's [`container`](https://github.com/apple/container) CLI. The project tracks the [`container k8s` feature discussion](https://github.com/apple/container/discussions/1673): local Kubernetes clusters implemented with k3s node containers, kubeconfig management, local image loading, and a path toward registry-backed development loops.

The repository name and plugin command stay Kubernetes-oriented: `container k8s ...`. k3s is the planned first backend, not the long-term product name.

## Current Status

This repository is at bootstrap stage. It includes the Swift plugin package, command surface, documentation, CI, Homebrew formula scaffolding, and release package automation. Runtime implementation is intentionally tracked in [PLAN.md](PLAN.md) before the first cluster-control code lands.

The initial command surface mirrors the Apple discussion:

```sh
container k8s run my-cluster
container k8s create my-cluster
container k8s list
container k8s load-image my-cluster my-app:latest
container k8s write-config my-cluster
container k8s get-kubeconfig my-cluster
container k8s delete my-cluster
```

## Design Direction

- Use Swift and SwiftPM for the plugin, matching the nearby `container-compose` repository and the language shape of `apple/container`.
- Start with a single-node k3s control-plane cluster that runs directly on Apple container runtime primitives.
- Label all runtime resources with `plugin=k8s` and cluster/node metadata so lifecycle commands are scoped and repeatable.
- Treat kubeconfig edits as a first-class safety boundary: generated contexts must be identifiable, reversible, and scriptable.
- Support `load-image` for the first MVP, while designing registry integration early enough that normal build-tag-push workflows do not become an afterthought.
- Keep CNI and kernel assumptions explicit so add-ons such as Cilium can be evaluated against a known compatibility matrix.

## Documentation

- [INSTALL.md](INSTALL.md): install the Homebrew package and register the plugin with `container`.
- [BRANCHES.md](BRANCHES.md): understand active `main` development, semantic package tags, and Homebrew formula policy.
- [BUILD.md](BUILD.md): build, test, package, and run contributor validation.
- [DESIGN.md](DESIGN.md): understand the plugin boundary and planned runtime model.
- [PLAN.md](PLAN.md): review the staged implementation roadmap based on the Apple discussion.
- [STATUS.md](STATUS.md): get the current branch, packaging, and implementation state.
- [CONTRIBUTING.md](CONTRIBUTING.md): prepare focused, reviewable changes.
- [SUPPORT.md](SUPPORT.md): ask for help or report non-security issues.
- [SECURITY.md](SECURITY.md): report security issues.

## License

This project uses the Apache License, Version 2.0, matching the license used by [`apple/container`](https://github.com/apple/container).
