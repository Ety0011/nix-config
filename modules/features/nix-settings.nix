{ ... }:
let
  gcOptions = "--delete-older-than 7d";
in
{
  flake.modules.nixos.nix-settings = {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      optimise = {
        automatic = true;
        dates = [ "03:00" ]; # sunday 3am, after gc
      };
      gc = {
        automatic = true;
        dates = "Sun 02:00";
        options = gcOptions;
        persistent = true;
      };
    };
  };

  flake.modules.darwin.nix-settings = {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      optimise = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 3;
          Minute = 0;
        }; # sunday 3am, after gc
      };
      gc = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
        options = gcOptions;
      };
    };
  };
}
