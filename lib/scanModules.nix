{ lib }:
path:
builtins.map (f: lib.path.append path f) (
  builtins.attrNames (
    lib.attrsets.filterAttrs (
      path: _type:
      (_type == "directory") || ((path != "default.nix") && lib.strings.hasSuffix ".nix" path)
    ) (builtins.readDir path)
  )
)
