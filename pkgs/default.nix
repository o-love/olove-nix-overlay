{ callPackage, lib }:

let
  entries = builtins.readDir ./.;
  packageDirs = lib.filterAttrs (
    name: type:
    type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
  ) entries;
in
lib.mapAttrs (name: _: callPackage (./. + "/${name}") { }) packageDirs
