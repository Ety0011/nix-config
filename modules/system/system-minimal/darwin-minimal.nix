{ inputs, ... }:
{
  # Layer 1 — absolute minimum required for every Darwin host.

  flake.modules.darwin.system-minimal =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      # Expose nixpkgs-unstable as pkgs.unstable everywhere in the system.
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config system;
          };
          # TODO: move this in appropriate place
          direnv = _prev.direnv.overrideAttrs (_: {
            doCheck = false;
            checkPhase = "true";
            doInstallCheck = false;
            installCheckPhase = "true";
          });
        })
      ];

      system.stateVersion = 6;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://cache.nixos.org?priority=10"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        trusted-users = [
          "root"
          "@wheel"
        ];

        download-buffer-size = 1024 * 1024 * 1024;
      };

      nix.extraOptions = ''
        warn-dirty = false
        keep-outputs = true
      '';

      # Automatic GC every Sunday at 02:00, optimise afterwards at 03:00
      nix.gc = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
        options = "--delete-older-than 7d";
      };
      nix.optimise = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 3;
          Minute = 0;
        };
      };
    };
}
