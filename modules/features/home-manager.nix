# Each Role's system module pulls in its homeManager counterpart for every
# User on the Host.
{ inputs, config, ... }:
let
  settings = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "home-manager.backup";
    home-manager.sharedModules = [ config.flake.modules.homeManager.base ];
  };
in
{
  flake.modules.darwin.base = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    config = settings;
  };

  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    config = settings;
  };

  flake.modules.homeManager.base = {
    programs.home-manager.enable = true;
  };
}
