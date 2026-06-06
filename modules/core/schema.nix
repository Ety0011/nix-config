{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  hostSubmodule = { ... }: {
    options = {
      platform = lib.mkOption {
        type = lib.types.enum [
          "darwin"
          "nixos"
        ];
      };
      system = lib.mkOption { type = lib.types.str; };
      stateVersion = lib.mkOption { type = lib.types.either lib.types.int lib.types.str; };
      activeUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  feat = name: lib.mkEnableOption name;
  allowed = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  userSubmodule = { name, ... }: {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      features = {
        git = {
          enable = feat "git";
          allowed = allowed;
        };
        zsh = {
          enable = feat "zsh";
          allowed = allowed;
        };
        ssh = {
          enable = feat "ssh";
          allowed = allowed;
        };
        direnv = {
          enable = feat "direnv";
          allowed = allowed;
        };
        starship = {
          enable = feat "starship";
          allowed = allowed;
        };
        nixTools = {
          enable = feat "nixTools";
          allowed = allowed;
        };
        sops = {
          enable = feat "sops";
          allowed = allowed;
        };
        syncthing = {
          enable = feat "syncthing";
          allowed = allowed;
        };
      };
    };
  };
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.treefmt-nix.flakeModule
  ];

  config.systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      darwinConfigurations = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
      };
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostSubmodule);
      default = { };
      description = "Host declarations. Evaluator generates configurations from these.";
    };

    users.profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule userSubmodule);
      default = { };
      description = "User profiles. Key must match darwin/nixos/home module name.";
    };
  };
}
