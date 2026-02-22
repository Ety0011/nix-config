{ lib }:
path:
builtins.attrNames (
  lib.attrsets.filterAttrs (_: _type: _type == "directory") (builtins.readDir path)
)
