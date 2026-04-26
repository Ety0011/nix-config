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

  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      # flake-parts has no built-in support for darwinConfigurations.
      darwinConfigurations = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "nix-darwin system configurations.";
      };

      # Common modules shared across all NixOS and Darwin hosts.
      # Declared here as flake.common (not flake.modules.common) because
      # flake.modules is owned by flake-parts and does not support extension.
      common = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
        description = "Modules shared across all NixOS and Darwin hosts.";
      };
    };
  };
}
