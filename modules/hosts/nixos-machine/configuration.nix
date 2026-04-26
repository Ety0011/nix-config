{ inputs, ... }:
let
  hostName = "nixos-machine";
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos system hostName;

  flake.modules.nixos.${hostName} = {
    imports = with inputs.self.modules.nixos; [ base ];
  };
}
