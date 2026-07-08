# Status

`container-k8s` is in repository bootstrap.

## Current State

- GitHub repository: `stephenlclarke/container-k8s`
- Local checkout: `~/github/container-k8s`
- Default branch: `main`
- Plugin command: `container k8s ...`
- First backend target: k3s
- Runtime implementation: not started

## Validation

The current validation target is:

```sh
make ci
```

This covers coverage-tool unit tests, Markdown linting, formula syntax checks, Swift tests with coverage instrumentation, the 80 percent minimum coverage gate, the debug build, and CLI smoke tests.

Current source coverage is above the minimum gate:

```text
Swift coverage: 92.37%
```

## Packaging

Debug and release archives use this layout:

```text
k8s/bin/k8s
k8s/config.toml
k8s/resources/build-info.json
```

Stable packages use `Formula/container-k8s.rb`. Main validation packages prove the current branch can build an archive but do not update Homebrew.

## Known Gaps

- Cluster creation is not implemented yet.
- The k3s node image does not exist yet.
- Kubeconfig merge logic is not implemented yet.
- Image loading is not implemented yet.
- SonarCloud is wired but needs the project binding and repository secret before analysis publishes.
