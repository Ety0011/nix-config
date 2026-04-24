{ inputs, ... }:
{
  # System policy shared by every Darwin host.
  # Contains only host-level concerns — no user preferences.

  flake.modules.darwin.host-base =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;

      # pkgs.unstable overlay — this must live here (system module context)
      # because it controls what pkgs looks like inside nix-darwin modules,
      # services, and home-manager. The perSystem overlay in flake/nixpkgs.nix
      # is a separate instance used only for flake-level outputs (formatter etc.).
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config system;
          };
        })
      ];

      system.stateVersion = 6;

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

      # Darwin uses launchd-style interval scheduling (not systemd dates)
      nix.gc = {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
        options = "--delete-older-than 7d";
      };
      nix.optimise = {
        automatic = true;
        interval = { Weekday = 0; Hour = 3; Minute = 0; };
      };

      imports = with inputs.self.modules.darwin; [
        home-manager-wiring
        sops
      ];
    };
}
