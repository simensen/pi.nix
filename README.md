# pi-mono.nix

A small Nix flake for [pi](https://github.com/earendil-works/pi), the terminal coding agent. It gives you:

- `nix run`
- `nix build`
- a small NixOS module for declarative setup

## Why

The upstream `pi` repo does not ship a `flake.nix`, so this exists to make pi easy to use from Nix without going through npm/node.

See [#2310](https://github.com/earendil-works/pi/issues/2310) for context.

## Packaging model

This flake packages **upstream prebuilt release binaries** rather than building pi from source.

- For each tagged upstream release, the platform-specific tarball
  (`pi-{darwin,linux}-{arm64,x64}.tar.gz`) is downloaded from GitHub Releases
  and unpacked under `$out/libexec/pi/`.
- The pinned release tag and per-system tarball URL + SHA-256 hash live in
  [`VERSION.json`](./VERSION.json). Nix verifies the hash on every build, so
  the binary provenance is reproducible.
- The real `pi` executable is wrapped as `$out/bin/pi`, with `nodejs`, `git`,
  `ripgrep`, and `fd` placed on `PATH` and `NPM_CONFIG_PREFIX` defaulted to
  `$HOME/.local/share/pi/npm-prefix` so user-level `npm i -g` keeps working.
- Sibling runtime assets shipped in the tarball (`package.json`,
  `photon_rs_bg.wasm`, `theme/`, `assets/`, `export-html/`, `docs/`,
  `examples/`, `CHANGELOG.md`, `README.md`) are preserved alongside the
  binary.
- On Linux, `autoPatchelfHook` rewrites the Bun-compiled binary against the
  Nix store (with `stdenv.cc.cc.lib` and `zlib` available as runtime deps).
- Supported systems: `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`,
  `x86_64-linux`. Windows is not supported.

### Tradeoff vs. building from source

Pros of the prebuilt approach:

- No npm lockfile, `buildNpmPackage`, `importNpmLock`, or vendored dep hash
  to maintain.
- No Bun toolchain dependency at build time.
- Updates are a single `update.sh` run that bumps the tag and re-pins
  per-system tarball hashes.

Cons / caveats:

- The shipped binary is opaque; you trust the upstream release artifact (the
  hash pin in `VERSION.json` makes that trust verifiable but not auditable
  the way a source build would be).
- Patches/local modifications to pi require rebuilding the upstream release
  out-of-band; this flake does not patch sources.
- `meta.sourceProvenance` is marked `binaryNativeCode`, which Nixpkgs
  consumers may surface as a warning.

## Run

```sh
nix run github:lukasl-dev/pi-mono.nix
```

## Build

```sh
nix build .#coding-agent
```

## Updating

`./update.sh` checks the upstream repo for the latest `vX.Y.Z` tag, and if it
differs from the pinned `rev` in `VERSION.json`, prefetches each per-system
tarball, records the SHA-256, and verifies the host build still succeeds.
A scheduled GitHub Actions workflow runs this daily and commits/tags any
version bumps.

## NixOS Module

```nix
# flake.nix
{
  inputs.pi-mono.url = "github:lukasl-dev/pi-mono.nix";
  # ...
}

# pi-mono.nix
{ config, inputs, pkgs, ... }:
{
  imports = [
    inputs.pi-mono.nixosModules.default
  ];

  programs.pi.coding-agent = {
    enable = true;

    # custom package
    # package = inputs.pi-mono.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;

    # target users
    # users = [ "lukas" ]; # defaults to all normal users

    # appended to the system prompt
    # rules = ''
    #   # AGENTS.md
    #   Be concise.
    # '';

    # extra skills
    # skills = [ ./skills/my-skill ];

    # extra extensions
    # extensions = [ ./extensions/my-extension.ts ];

    # extra themes
    # themes = [ ./themes/catppuccin-mocha.json ];

    # extra prompt templates
    # promptTemplates = [ ./prompts ./prompt-templates/review.md ];

    # ~/.pi/agent/models.json
    # models = ./models.json;

    # extra raw CLI flags
    # extraFlags = [ "--provider" "openai" "--model" "gpt-5" ];

    # environment variables or env file
    # environment = {
    #   OPENAI_API_KEY = config.age.secrets.openai.path;
    # };
    # environment = ./pi.env;
  };
}
```

## Overlay

```nix
# flake.nix
{
  inputs.pi-mono.url = "github:lukasl-dev/pi-mono.nix";
  # ...
}

# configuration.nix or a module
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.pi-mono.overlays.default ];

  environment.systemPackages = [
    # aliases to inputs.pi-mono.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
    pkgs.pi-coding-agent
  ];
}
```
