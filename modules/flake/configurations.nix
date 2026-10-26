# Hosts declare `configurations.<class>.<host>.module`; this maps them to
# `*Configurations` and a `checks` entry per Host. Host modules only — no
# Feature or User fields belong here (see docs/adr/0001).
{
  inputs,
  lib,
  config,
  ...
}:
let
  mkOption =
    class:
    lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "${class} module for this Host";
          };
        }
      );
      default = { };
    };

  mkSystems =
    builder: hostModule:
    lib.mapAttrs (
      name: host:
      builder {
        modules = [
          (hostModule name)
          host.module
        ];
      }
    );

  mkChecks =
    class:
    lib.mapAttrsToList (
      name: built: {
        ${built.config.nixpkgs.hostPlatform.system}."${class}-${name}" = built.config.system.build.toplevel;
      }
    );

  nixosConfigurations = mkSystems inputs.nixpkgs.lib.nixosSystem (name: {
    networking.hostName = lib.mkDefault name;
  }) config.configurations.nixos;

  darwinConfigurations = mkSystems inputs.nix-darwin.lib.darwinSystem (name: {
    networking.hostName = lib.mkDefault name;
    networking.computerName = lib.mkDefault name;
    networking.localHostName = lib.mkDefault name;
  }) config.configurations.darwin;
in
{
  options.configurations = {
    nixos = mkOption "NixOS";
    darwin = mkOption "nix-darwin";
  };

  config.flake = {
    inherit nixosConfigurations darwinConfigurations;
    checks = lib.mkMerge (
      mkChecks "nixos" nixosConfigurations ++ mkChecks "darwin" darwinConfigurations
    );
  };
}
