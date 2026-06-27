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

This covers Markdown linting, formula syntax checks, Swift tests, a placeholder coverage gate, the debug build, and CLI smoke tests.

## Packaging

Debug and release archives use this layout:

```text
k8s/bin/k8s
k8s/config.toml
k8s/resources/build-info.json
```

The release lane uses `Formula/container-k8s.rb`; the snapshot lane uses `Formula/container-k8s-snapshot.rb`.

## Known Gaps

- Cluster creation is not implemented yet.
- The k3s node image does not exist yet.
- Kubeconfig merge logic is not implemented yet.
- Image loading is not implemented yet.
- SonarCloud is wired but needs the project binding and repository secret before analysis publishes.
