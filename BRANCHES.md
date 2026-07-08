# Branch Guide

This repository uses `main` as the active, releasable development branch. README badges, full CI, CodeQL, SonarCloud quality reporting, package validation, and normal integration work all stay on `main`.

Use short-lived topic branches only for review or recovery. Land validated work back on `main`, then delete those branches unless they are still needed for an open review.

Do not create additional long-lived integration or packaging lanes. Historical non-main branches are references only.

## Package Automation

The prebuilt package workflow publishes two kinds of package artifacts:

- Main validation packages from successful `main` CI runs. These prove the current branch can build a release archive but do not update Homebrew.
- Stable packages from manual workflow dispatch against a bare semantic source tag such as `0.1.0`. These update `stephenlclarke/tap/container-k8s` when the tap token is available.

The tap update requires the `HOMEBREW_TAP_TOKEN` repository secret with permission to push to `stephenlclarke/homebrew-tap`.

Packaged builds include a plugin `build-info.json` file. `container k8s version` reads that file and reports the package lane, branch, commit, build type, and `container` pin used for the package.

## Local Branch Selection

For active development:

```sh
git -C ~/github/container-k8s checkout main
git -C ~/github/container checkout main
```

The current Swift package is intentionally standalone while the bootstrap command surface settles. Future direct `apple/container` API integration should use the sibling `~/github/container` checkout and keep the pin in `APPLE_CONTAINER_REF` current.

## Upstreaming Rule

Runtime changes needed in [`apple/container`](https://github.com/apple/container) should be split into small Apple-facing branches before opening pull requests upstream. Keep generic runtime primitives out of this repository when they are useful beyond Kubernetes cluster management.

Kubernetes-specific behavior stays here, including k3s node image construction, kubeconfig ownership, cluster labels, local registry opinionation, and compatibility documentation.
