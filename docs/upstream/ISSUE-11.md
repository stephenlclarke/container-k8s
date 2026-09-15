# Issue 11: make SonarQube analysis exact and authoritative

## Problem

The scanner configuration published the semantic package version `0.1.0`
instead of the analyzed commit. The workflow also trusted the standard quality
gate without independently proving that authoritative `main` contained no
unresolved issue or unreviewed hotspot.

## Design

- Derive `sonar.projectVersion` from the checked-out Git commit and reject any
  supplied override that does not equal that commit.
- Check out the pull-request head rather than GitHub's synthetic merge commit.
- Validate the shared SonarQube `Previous version` project policy.
- Inspect new-code findings for pull requests and all unresolved findings for
  `main` after each successful scan.
- Keep fork and Dependabot pull requests free of secret-dependent execution.

No runtime, Kubernetes, package, or release behavior changes.

Tracking issue: [#11](https://github.com/stephenlclarke/container-k8s/issues/11)
