{ inputs, ... }:
{
  # Config shared across every host regardless of platform.
  # Injected automatically by mkNixos and mkDarwin in lib.nix.
  flake.common.base = {
    nixpkgs.config.allowUnfree = true;

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

    # System-level home-manager wiring options — identical on both platforms.
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "home-manager.backup";
  };
}
