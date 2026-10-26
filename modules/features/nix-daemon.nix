let
  settings = {
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
      download-buffer-size = 1024 * 1024 * 1024;
      max-jobs = "auto";
      connect-timeout = 5;
    };
    nix.extraOptions = ''
      warn-dirty = false
      keep-outputs = true
      use-xdg-base-directories = true
    '';
  };
in
{
  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      imports = [ settings ];
      # macOS admins are in `admin`; `wheel` holds only root.
      nix.settings.trusted-users = [ "@admin" ];
      nix.package = pkgs.nix;
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
      launchd.daemons.nix-gc-system-profiles = {
        command = "/bin/sh -c '/nix/var/nix/profiles/system/sw/bin/nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system'";
        serviceConfig = {
          RunAtLoad = false;
          StartCalendarInterval = [
            {
              Weekday = 0;
              Hour = 3;
              Minute = 30;
            }
          ];
        };
      };
    };

  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      imports = [ settings ];
      nix.settings.trusted-users = [ "@wheel" ];
      nix.package = pkgs.nix;
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
