{ inputs, ... }:
let
  hostName = "nixos-machine";
  system = "x86_64-linux";
  stateVersion = "25.05";
in
{
  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = with inputs.self.modules.nixos; [
      # 1. base — universal system policy for all nixos hosts
      base

      # 2. host — identity and platform settings specific to this machine
      {
        nixpkgs.hostPlatform = system;
        networking.hostName = hostName;
        system.stateVersion = stateVersion;
      }

      # 3. users — who lives on this machine
      ety
    ];
  };
}
