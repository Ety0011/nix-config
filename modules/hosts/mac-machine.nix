{ inputs, ... }:
let
  hostName = "Etiennes-MacBook-Pro";
in
{
  flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
    modules = with inputs.self.modules.darwin; [
      { nixpkgs.hostPlatform = "aarch64-darwin"; }
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
