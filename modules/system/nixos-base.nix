{ inputs, ... }:
{
  # NixOS-specific base config. Shared config lives in common.base.
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      system.stateVersion = "25.05";

      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config;
            system = pkgs.stdenv.hostPlatform.system;
          };
        })
      ];

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

      imports = [
        inputs.home-manager.nixosModules.home-manager
      ] ++ (with inputs.self.modules.nixos; [
        diskoWiring
        sops
        ssh
      ]);
    };
}
