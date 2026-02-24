{ inputs, ... }:
{
  flake.modules.nixos.disko-wiring = {
    imports = [ inputs.disko.nixosModules.disko ];
  };
}
