{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.treefmt-nix.flakeModule
  ];

  # flake-parts has no built-in support for darwinConfigurations, so we declare
  # it as a typed option here so the module system can validate it properly.
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      darwinConfigurations = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "nix-darwin system configurations.";
      };
    };
  };
}
