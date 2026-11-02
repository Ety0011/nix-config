{ config, ... }:
{
  configurations.darwin.helios.module = {
    imports = with config.flake.modules.darwin; [
      base
      ety
      backup-home
    ];
    nixpkgs.hostPlatform = "aarch64-darwin";
    sops.defaultSopsFile = ../../../secrets/helios.yaml;
    # Per-device key, kept out of backup-home; recovery is in docs/adr/0005.
    sops.age.keyFile = "/Users/ety/Library/Application Support/sops/age/keys.txt";
    # Live install: never change these.
    system.stateVersion = 6;
    home-manager.users.ety.home.stateVersion = "24.11";
  };
}
