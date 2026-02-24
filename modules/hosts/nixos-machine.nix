{ inputs, ... }:
let
  hostName = "nixos-machine";
in
{
  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = with inputs.self.modules.nixos; [
      { nixpkgs.hostPlatform = "x86_64-linux"; }
      { networking.hostName = hostName; }
      home-manager-wiring
      disko-wiring
      cli
      sops
      ety
      # hardware-configuration.nix
    ];
  };
}
