{ lib, root }:
lib.extend (
  _: _: {
    custom = {
      makeConfiguration = import ./makeConfiguration.nix;
      scanModules = import ./scanModules.nix { inherit lib; };
      scanDirs = import ./scanDirs.nix { inherit lib; };
      relativeToRoot = lib.path.append root;
    };
  }
)
