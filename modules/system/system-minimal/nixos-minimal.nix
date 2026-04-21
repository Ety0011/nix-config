{ inputs, ... }:
{
  # Layer 1 — absolute minimum required for every NixOS host.
  # Every nixosConfiguration inherits this through the system-cli chain.

  flake.modules.nixos.system-minimal =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      # Expose nixpkgs-unstable as pkgs.unstable everywhere in the system.
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config;
            system = pkgs.stdenv.hostPlatform.system;
          };
        })
      ];

      system.stateVersion = "25.05";

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Binary caches — nix-community for community packages (e.g. sops-nix, disko)
        substituters = [
          "https://cache.nixos.org?priority=10"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        # Allow wheel users to control the nix daemon without sudo
        trusted-users = [
          "root"
          "@wheel"
        ];

        download-buffer-size = 1024 * 1024 * 1024; # 1 GiB
      };

      nix.extraOptions = ''
        warn-dirty = false
        keep-outputs = true
      '';

      # Automatic GC every Sunday at 02:00, optimise store afterwards at 03:00
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
    };
}
