{ inputs, ... }:
let
  hostName = "Etiennes-MacBook-Pro";
in
{
  flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
    modules = with inputs.self.modules.darwin; [
      { nixpkgs.hostPlatform = "aarch64-darwin"; }
      {
        nixpkgs.overlays = [
          (final: prev: {
            direnv = prev.direnv.overrideAttrs (_: {
              doCheck = false;
              checkPhase = "true";
              doInstallCheck = false;
              installCheckPhase = "true";
            });
          })
        ];
      }
      { nixpkgs.config.allowUnfree = true; }
      {
        networking.hostName = hostName;
        networking.computerName = hostName;
      }
      home-manager-wiring
      cli
      sops
      window-manager
      system-defaults
      ety
    ];
  };
}
