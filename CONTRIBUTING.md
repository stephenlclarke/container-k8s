# Contributing

Thank you for helping shape `container-k8s`.

## Development Expectations

- Keep changes focused on one issue or one coherent feature.
- Prefer small Swift boundaries that can map to future `apple/container` upstream changes.
- Update [PLAN.md](PLAN.md), [DESIGN.md](DESIGN.md), or [STATUS.md](STATUS.md) when behavior, compatibility, or branch state changes.
- Add focused tests for material implementation changes.
- Use Conventional Commits for commit messages and pull request titles.

## Local Workflow

```sh
make ci
```

For faster checks while editing docs:

```sh
make check
```

For Swift-only work:

```sh
make test
make build
```

## Branching

Active work targets `main`; see [BRANCHES.md](BRANCHES.md).

## Security And Secrets

Do not commit credentials, tokens, private keys, kubeconfig secrets, registry credentials, or private cluster logs. See [SECURITY.md](SECURITY.md) for reporting guidance.
