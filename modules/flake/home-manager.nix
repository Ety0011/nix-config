{ inputs, ... }:
let
  backupFileExtension = "home-manager.backup";
in
{
  flake.modules.nixos.home-manager-wiring = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = backupFileExtension;
  };

  flake.modules.darwin.home-manager-wiring = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = backupFileExtension;
  };
}
