# container-k8s Design

`container-k8s` is a standalone plugin for Apple's [`container`](https://github.com/apple/container) CLI. It is designed to provide local Kubernetes development clusters while staying close to the Swift package and plugin conventions used by `apple/container` and the nearby `container-compose` repository.

## Goals

- Expose Kubernetes-oriented commands through `container k8s ...`.
- Use k3s as the first cluster backend because it is small enough to run as a node image on the Apple container runtime.
- Keep single-node cluster creation, image loading, kubeconfig handling, and teardown predictable enough for daily local development.
- Make every generated runtime resource discoverable by label.
- Keep kubeconfig edits reversible and obvious.
- Leave room for registry-backed workflows, worker nodes, and service exposure without renaming the project.

## Non-Goals For The First Slice

- No attempt to support every Kubernetes distribution.
- No multi-node scheduling until the single-node control-plane path is reliable.
- No hidden replacement for `kubectl`.
- No promise that every CNI or eBPF-heavy add-on works before kernel and sysctl requirements are documented.

## Command Surface

The bootstrap command surface follows the Apple discussion:

| Command | Intended behavior |
| --- | --- |
| `run` | Create and start a single-node k3s control-plane cluster, then write kubeconfig. |
| `create` | Create the node container and persistent state without starting it. |
| `delete` | Stop and remove cluster resources and generated kubeconfig entries. |
| `list` | Discover clusters by `plugin=k8s` labels and render cluster/node state. |
| `load-image` | Save a local image from `container` image storage and import it into the node containerd. |
| `write-config` | Merge the generated cluster kubeconfig into `~/.kube/config`. |
| `get-kubeconfig` | Print a generated kubeconfig for scripting or manual merging. |

## Runtime Model

The planned single-node cluster has one control-plane node container. The node image layers `rancher/k3s` with an entrypoint that handles Apple runtime specifics:

- native containerd snapshotter selection
- cgroup v2 setup
- required namespaced sysctls for Kubernetes networking
- stable kubeconfig export
- eventual `registries.yaml` injection for local registry mirrors

Cluster containers should be created with deterministic labels:

```text
plugin=k8s
io.container-k8s.cluster=<cluster>
io.container-k8s.node=<node>
io.container-k8s.role=control-plane
```

Those labels are the ownership boundary for `list`, `delete`, and future multi-node commands.

## Kubeconfig Ownership

Generated kubeconfig entries should use stable names:

```text
cluster: container-k8s-<cluster>
user: container-k8s-<cluster>
context: container-k8s-<cluster>
```

`write-config` owns only entries with those names. It should not rewrite unrelated user-managed contexts. `delete` should remove only generated entries for the selected cluster.

The API server address must be rewritten from the in-node address to a host-reachable endpoint such as `127.0.0.1:<published-port>`.

## Registry Direction

`load-image` is valuable for the first working loop, but normal Kubernetes development usually wants build, tag, push, deploy. The design should keep registry support close to the MVP:

- Detect or create a well-known local registry container.
- Allow `--registry none` and `--registry <name-or-host>` escape hatches.
- Configure k3s `registries.yaml` so pods can pull from the local registry.
- Keep TLS and authentication optional, with room for `mkcert` when available.

## Compatibility Notes

CNI and kernel compatibility should be documented as features are tested. Cilium is an explicit evaluation target because it depends on kernel options and eBPF behavior that may not be available in every Apple container runtime configuration.

Compatibility failures should be reported as one of:

- plugin implementation gap
- missing `apple/container` runtime primitive
- Apple kernel configuration limitation
- k3s or Kubernetes addon limitation

That split keeps upstream issues and local plugin work reviewable.
