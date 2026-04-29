{ inputs, ... }:
let
  hostName = "Etiennes-MacBook-Pro";
  system = "aarch64-darwin";
  stateVersion = 6;
in
{
  flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
    modules = with inputs.self.modules.darwin; [
      # 1. base — universal system policy for all darwin hosts
      base

      # 2. host — identity and platform settings specific to this machine
      {
        nixpkgs.hostPlatform = system;
        networking.hostName = hostName;
        networking.computerName = hostName;
        system.stateVersion = stateVersion;
      }

      # 3. users — who lives on this machine
      ety
    ];
  };
}
