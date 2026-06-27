# Implementation Plan

This roadmap is based on [`apple/container` discussion 1673](https://github.com/apple/container/discussions/1673) and the repository conventions used by `container-compose`.

## Stage 0: Repository Bootstrap

- [x] Create `stephenlclarke/container-k8s`.
- [x] Clone it to `~/github/container-k8s`.
- [x] Add Swift plugin package with `k8s` executable.
- [x] Add README badges and project documentation.
- [x] Add `main`, `release/*`, and `snapshot/*` CI/CD lane scaffolding.
- [x] Add Homebrew release and snapshot formula scaffolding.

## Stage 1: Single-Node Cluster Proof

- [ ] Build or pull the k3s node image used by the plugin.
- [ ] Start one control-plane node container with required capabilities, sysctls, mounts, and published API server port.
- [ ] Poll the node until the Kubernetes API server is reachable.
- [ ] Generate host-reachable kubeconfig.
- [ ] Keep all generated resources labeled with plugin and cluster metadata.

Acceptance sketch:

```sh
container k8s run demo
kubectl --context container-k8s-demo get nodes
container k8s delete demo
```

## Stage 2: Kubeconfig Safety

- [ ] Implement `get-kubeconfig`.
- [ ] Implement `write-config` with generated entry ownership.
- [ ] Implement `delete` cleanup for generated kubeconfig entries.
- [ ] Add tests for merge, replacement, current-context, and removal behavior.

## Stage 3: Cluster Listing And Lifecycle

- [ ] Implement `list` from `plugin=k8s` labels.
- [ ] Implement stopped/running state rendering.
- [ ] Implement `create` without start.
- [ ] Implement `delete --force` for running clusters.

## Stage 4: Image Loading

- [ ] Resolve short image references to canonical references.
- [ ] Export from the Apple `container` image store as OCI archive.
- [ ] Stream or copy the archive into the node.
- [ ] Import with `ctr images import`.
- [ ] Verify kubelet can schedule a pod from the loaded image without pulling.

## Stage 5: Registry-Aware Development

- [ ] Decide default registry opinionation.
- [ ] Add `--registry none`, `--registry auto`, and `--registry <value>` design.
- [ ] Configure k3s `registries.yaml`.
- [ ] Document local build-tag-push workflows.

## Stage 6: Future Cluster Features

- [ ] Multi-node clusters with `--workers N`.
- [ ] Image loading across all nodes.
- [ ] Service exposure and load-balancing behavior.
- [ ] Cilium and alternate CNI compatibility matrix.
- [ ] Direct `apple/container` API adapters where they reduce CLI parsing and improve testability.
