{ config, ... }:
{
  configurations.nixos.typhon.module = {
    imports =
      (with config.flake.modules.nixos; [
        base
        ety
      ])
      ++ [ ./_hardware.nix ];
    system.stateVersion = "26.05";
    home-manager.users.ety.home.stateVersion = "26.05";
  };
}
