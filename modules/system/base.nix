{ inputs, withSystem, self, ... }:
let
  shared = {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "root" "@wheel" ];
      download-buffer-size = 1024 * 1024 * 1024;
    };

    nix.extraOptions = ''
      warn-dirty = false
      keep-outputs = true
    '';

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "home-manager.backup";
  };
in
{
  flake.modules.darwin.base =
    { config, ... }:
    shared // {
      nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);

      nix.registry.nixpkgs.flake = inputs.nixpkgs-darwin;

      nix.gc = {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
        options = "--delete-older-than 7d";
      };
      nix.optimise = {
        automatic = true;
        interval = { Weekday = 0; Hour = 3; Minute = 0; };
      };

      imports = [
        inputs.home-manager.darwinModules.home-manager
      ] ++ (with self.modules.darwin; [
        systemSettings
        sops
        zsh
        direnv
      ]);
    };

  flake.modules.nixos.base =
    { config, ... }:
    shared // {
      nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);

      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      nix.gc = {
        automatic = true;
        dates = "Sun 02:00";
        options = "--delete-older-than 7d";
        persistent = true;
      };
      nix.optimise = {
        automatic = true;
        dates = [ "Sun 03:00" ];
      };

      imports = [
        inputs.home-manager.nixosModules.home-manager
      ] ++ (with self.modules.nixos; [
        sops
        ssh
        zsh
        direnv
      ]);
    };

  flake.modules.homeManager.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.homeDirectory = lib.mkDefault (
        if pkgs.stdenv.isDarwin
        then "/Users/${config.home.username}"
        else "/home/${config.home.username}"
      );

      programs.home-manager.enable = true;
    };
}
