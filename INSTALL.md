# Installing container-k8s

This guide explains how to install the `container-k8s` plugin. Source build, test, and package steps are covered in [BUILD.md](BUILD.md); branch rules are covered in [BRANCHES.md](BRANCHES.md).

## Homebrew Formula

Homebrew installs use the stable package published from a bare semantic source tag:

| Formula | Build type | Use when |
| --- | --- | --- |
| `container-k8s` | release | Install this. It registers the `k8s` plugin payload with the active `container` CLI. |

The formula installs a prebuilt GitHub release asset. It does not build Swift source on the user's machine and does not require Xcode for normal installation.

## Requirements

- Apple silicon Mac.
- macOS with a compatible Apple `container` install.
- Homebrew.
- No running `container` service from a different install source while installing or upgrading the plugin.

## Install From The Aggregate Tap

Install the latest stable package:

```sh
brew tap stephenlclarke/tap
brew install stephenlclarke/tap/container
brew install stephenlclarke/tap/container-k8s
mkdir -p "$(brew --prefix container)/libexec/container-plugins"
ln -sfn "$(brew --prefix container-k8s)/libexec/container-plugins/k8s" "$(brew --prefix container)/libexec/container-plugins/k8s"
brew services restart container
container k8s version
```

## Install From A Source Branch

Use this path only when testing a source branch directly, not for normal Homebrew installs:

```sh
branch=main
brew tap stephenlclarke/container-k8s https://github.com/stephenlclarke/container-k8s
git -C "$(brew --repo stephenlclarke/container-k8s)" fetch origin
git -C "$(brew --repo stephenlclarke/container-k8s)" checkout "$branch"
brew install stephenlclarke/container-k8s/container-k8s
```

Register the plugin with the Homebrew-installed `container` keg:

```sh
mkdir -p "$(brew --prefix container)/libexec/container-plugins"
ln -sfn "$(brew --prefix container-k8s)/libexec/container-plugins/k8s" "$(brew --prefix container)/libexec/container-plugins/k8s"
brew services restart container
container k8s version
```

## Install A Local Plugin Archive

Build a local plugin archive with `make package`, then install or replace the plugin under the active `container` install root:

```sh
sudo rm -rf /usr/local/libexec/container-plugins/k8s
sudo mkdir -p /usr/local/libexec/container-plugins
sudo tar -xzf container-k8s-plugin.tar.gz -C /usr/local/libexec/container-plugins
```

The resulting plugin layout is:

```text
/usr/local/libexec/container-plugins/k8s/bin/k8s
/usr/local/libexec/container-plugins/k8s/config.toml
/usr/local/libexec/container-plugins/k8s/resources/build-info.json
```

## Verify

Confirm that `container` discovers the plugin:

```sh
container k8s version
```

Show the runtime and plugin provenance:

```sh
container system version
container k8s version
container k8s version --format json
```

Run a read-only bootstrap command:

```sh
container k8s run demo --dry-run
```

## Upgrade

Upgrade the stable package and register the plugin again:

```sh
brew update
brew upgrade stephenlclarke/tap/container-k8s
mkdir -p "$(brew --prefix container)/libexec/container-plugins"
ln -sfn "$(brew --prefix container-k8s)/libexec/container-plugins/k8s" "$(brew --prefix container)/libexec/container-plugins/k8s"
brew services restart container
container k8s version
```

## Uninstall

Remove the plugin and Homebrew-installed `container` package:

```sh
brew services stop container || true
brew uninstall container-k8s container || true
brew untap stephenlclarke/tap || true
```

If you installed the plugin manually under `/usr/local`, remove it with:

```sh
sudo rm -rf /usr/local/libexec/container-plugins/k8s
```
