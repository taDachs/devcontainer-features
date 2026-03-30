
# Neovim (neovim)

A feature to install the Neovim text-editor

## Example Usage

```json
"features": {
    "ghcr.io/taDachs/devcontainer-features/neovim:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install_method | Installation method: 'ppa' adds a PPA repository, 'source' builds from git, 'apt' installs from default Ubuntu repositories | string | ppa |
| version | Git tag to build from when install_method is 'source' (e.g. 'stable', 'v0.9.5', 'master') | string | stable |
| ppa | PPA to add when install_method is 'ppa' | string | ppa:neovim-ppa/unstable |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/taDachs/devcontainer-features/blob/main/src/neovim/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
