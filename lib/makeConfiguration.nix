{
  inputs,
  lib,
  vars,
  hostname,
}:
let
  hostVars = import (lib.custom.relativeToRoot "hosts/${hostname}/vars.nix");
  hostOs = if lib.hasSuffix "darwin" hostVars.system then "darwin" else "nixos";
  system = hostVars.system;

  osArgs =
    {
      darwin = {
        builder = inputs.nix-darwin.lib.darwinSystem;
        homeManagerModule = inputs.home-manager.darwinModules.home-manager;
        configuration = "darwinConfigurations";
      };
      nixos = {
        builder = inputs.nixpkgs.lib.nixosSystem;
        homeManagerModule = inputs.home-manager.nixosModules.home-manager;
        configuration = "nixosConfigurations";
      };
    }
    .${hostOs};

  extraSpecialArgs = {
    inherit
      inputs
      hostname
      vars
      hostVars
      ;
  };

  specialArgs = extraSpecialArgs // {
    inherit lib;
  };

  nixpkgsModule = {
    nixpkgs.hostPlatform = system;
    nixpkgs.config.allowUnfree = true;
  };

  systemModules = [ (lib.custom.relativeToRoot "modules/${hostOs}") ];
  homeModules = [ (lib.custom.relativeToRoot "home/${hostOs}") ];
  hostSystemModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/system.nix") ];
  hostHomeModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/home.nix") ];

  homeManagerConfig = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "home-manager.backup";
    home-manager.extraSpecialArgs = extraSpecialArgs;
    home-manager.users.${vars.username}.imports = homeModules ++ hostHomeModules;
  };

  modules = [
    nixpkgsModule
  ]
  ++ [ osArgs.homeManagerModule ]
  ++ [ homeManagerConfig ]
  ++ systemModules
  ++ hostSystemModules;
in
{
  ${osArgs.configuration}.${hostname} = osArgs.builder { inherit system specialArgs modules; };
}
