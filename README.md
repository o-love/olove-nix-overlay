# nixpkgs overlay starter

This repository gives you a small overlay-first workflow for creating packages locally before contributing them to `nixpkgs`.

## What this repo exports

- `overlays.default`: an overlay you can import into another flake, NixOS config, or Home Manager config
- `packages.<system>.*`: the same packages exposed as direct flake outputs for easy local builds
- `devShells.<system>.default`: a shell with a few Nix lint/format tools

Packages are discovered automatically from the `pkgs/` directory. Every subdirectory with a `default.nix` file becomes a package attribute in the overlay.

## Layout

```text
.
├── flake.lock
├── flake.nix
├── overlay
│   └── default.nix
└── pkgs
    ├── default.nix
    └── hello-overlay
        └── default.nix
```

## Add a new package

1. Create a new directory under `pkgs/`, for example `pkgs/my-tool/`.
2. Add a `default.nix` file in that directory.
3. The package will automatically appear as `pkgs.my-tool` when the overlay is enabled.

Example:

```nix
{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "my-tool";
  version = "0.1.0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp my-tool $out/bin/my-tool
    chmod +x $out/bin/my-tool
    runHook postInstall
  '';

  meta = {
    description = "My local package";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
```

## Build a package from this repo

```bash
nix build .#hello-overlay
./result/bin/hello-overlay
```

When you add `pkgs/my-tool/default.nix`, build it with:

```bash
nix build .#my-tool
```

## Update the pinned nixpkgs revision

This repo includes a `flake.lock`, so everyone evaluates against the same `nixpkgs` revision by default.

Refresh it when you want newer packaging dependencies:

```bash
nix flake update
```

## Use the overlay from another flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    my-overlay.url = "path:/absolute/path/to/this/repo";
  };

  outputs = { nixpkgs, my-overlay, ... }: {
    packages.x86_64-linux.default =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ my-overlay.overlays.default ];
        };
      in
      pkgs.my-tool;
  };
}
```

## Use the overlay without flakes

```nix
let
  pkgs = import <nixpkgs> {
    overlays = [
      (import /absolute/path/to/this/repo/overlay)
    ];
  };
in
pkgs.my-tool
```

## Upstreaming later

Once a package works here, move it toward `nixpkgs` conventions:

- replace placeholder metadata with real `meta`
- make sure it builds in a clean environment
- add maintainers, tests, and platform restrictions where appropriate
- follow the layout and style used by similar packages in `nixpkgs`
