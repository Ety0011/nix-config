let
  settings = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      download-buffer-size = 1024 * 1024 * 1024;
      connect-timeout = 5;
      warn-dirty = false;
      use-xdg-base-directories = true;
    };
  };
in
{
  flake.modules.darwin.base = {
    imports = [ settings ];
    # macOS admins are in `admin`; `wheel` holds only root.
    nix.settings.trusted-users = [ "@admin" ];
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    nix.optimise.automatic = true;
  };

  flake.modules.nixos.base = {
    imports = [ settings ];
    nix.settings.trusted-users = [ "@wheel" ];
    nix.gc = {
      automatic = true;
      dates = "Sun 02:00";
      options = "--delete-older-than 7d";
    };
    nix.optimise = {
      automatic = true;
      dates = [ "Sun 03:00" ];
    };
  };
}
