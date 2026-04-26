{ inputs, ... }:
{
  flake.modules.nixos.diskoWiring = {
    imports = [ inputs.disko.nixosModules.disko ];
  };
}
