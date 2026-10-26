{ config, ... }:
{
  configurations.darwin.helios.module = {
    imports = with config.flake.modules.darwin; [
      base
      ety
    ];
    nixpkgs.hostPlatform = "aarch64-darwin";
    # Live install: never change these.
    system.stateVersion = 6;
    home-manager.users.ety.home.stateVersion = "24.11";
  };
}
