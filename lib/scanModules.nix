# scanModules.nix
{ lib }:

# Function: scan a directory for subdirs and .nix files
# Returns a list of paths
path:
builtins.map (f: lib.path.append path f) (
  builtins.attrNames (
    lib.attrsets.filterAttrs (
      path: _type:
      (_type == "directory") || ((path != "default.nix") && lib.strings.hasSuffix ".nix" path)
    ) (builtins.readDir path)
  )
)
