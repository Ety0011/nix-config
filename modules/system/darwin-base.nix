{ inputs, ... }:
{
  # Darwin-specific base config. Shared config lives in common.base.
  flake.modules.darwin.base =
    { ... }:
    {
      system.stateVersion = 6;

      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config system;
          };
        })
      ];

      nix.gc = {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
        options = "--delete-older-than 7d";
      };
      nix.optimise = {
        automatic = true;
        interval = { Weekday = 0; Hour = 3; Minute = 0; };
      };

      imports = [
        inputs.home-manager.darwinModules.home-manager
      ] ++ (with inputs.self.modules.darwin; [
        systemSettings
        sops
      ]);
    };
}
