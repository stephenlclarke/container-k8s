# Branch Guide

This repository uses `main` as the active development branch. README badges, full CI, CodeQL, SonarCloud quality reporting, and normal integration work all stay on `main`.

Frozen install branches are created from validated `main` commits when a release or snapshot should be made available through prebuilt GitHub release assets and the Homebrew tap.

## Branch Model

| Branch pattern | Purpose | CI profile | README badges |
| --- | --- | --- | --- |
| `main` | Active development and integration branch | Full CI, Quality, CodeQL, SonarCloud | SonarCloud and security badges stay visible. |
| `release/*` | Frozen release lane for installable release builds | Reduced package and formula validation | SonarCloud badges are removed automatically. |
| `snapshot/*` | Frozen snapshot lane for installable debug builds | Reduced package and formula validation | SonarCloud badges are removed automatically. |

This strategy follows the nearby `container-compose` repository: active development keeps the quality signal visible on one branch, while release and snapshot branches are frozen packaging lanes.

## Frozen Branch Automation

Pushing a `release/*` or `snapshot/*` branch starts the frozen branch workflow:

1. Prepare the branch by removing SonarCloud badge lines from `README.md`.
2. Commit that README change back to the frozen branch when needed.
3. On the follow-up workflow run for the prepared branch tip, build the prebuilt package.
4. Publish the package to a branch-specific `homebrew-*` GitHub release.
5. Update `stephenlclarke/homebrew-tap` so Homebrew installs the matching frozen asset.

`release/*` branches build release packages. `snapshot/*` branches build debug packages.

The tap update requires the `HOMEBREW_TAP_TOKEN` repository secret with permission to push to `stephenlclarke/homebrew-tap`.

Frozen branch packages include a plugin `build-info.json` file. `container k8s version` reads that file and reports the lane, branch, commit, build type, and `container` pin used for the package.

## Local Branch Selection

For active development:

```sh
git -C ~/github/container-k8s checkout main
git -C ~/github/container checkout main
```

For a frozen release or snapshot branch, check out the matching `container-k8s` branch and the `container` revision pinned by `APPLE_CONTAINER_REF`:

```sh
git -C ~/github/container-k8s checkout release/example
git -C ~/github/container fetch origin
git -C ~/github/container checkout "$(cat ~/github/container-k8s/APPLE_CONTAINER_REF)"
```

The current Swift package is intentionally standalone while the bootstrap command surface settles. Future direct `apple/container` API integration should use the sibling `~/github/container` checkout and keep the pin in `APPLE_CONTAINER_REF` current.

## Upstreaming Rule

Runtime changes needed in [`apple/container`](https://github.com/apple/container) should be split into small Apple-facing branches before opening pull requests upstream. Keep generic runtime primitives out of this repository when they are useful beyond Kubernetes cluster management.

Kubernetes-specific behavior stays here, including k3s node image construction, kubeconfig ownership, cluster labels, local registry opinionation, and compatibility documentation.
