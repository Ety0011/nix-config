{
  inputs,
  lib,
  vars,
  hostname,
}:
let
  hostVars = import (lib.custom.relativeToRoot "hosts/${hostname}/vars.nix");
  system = hostVars.system;
  platform = if lib.hasSuffix "darwin" system then "darwin" else "nixos";

  forPlatform = attrs: attrs.${platform};

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

  systemModules = [ (lib.custom.relativeToRoot "modules/${platform}") ];
  homeModules = [ (lib.custom.relativeToRoot "home/${platform}") ];

  hostSystemModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/system.nix") ];
  hostHomeModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/home.nix") ];

  homeManagerModule = forPlatform {
    darwin = inputs.home-manager.darwinModules.home-manager;
    nixos = inputs.home-manager.nixosModules.home-manager;
  };

  homeManagerConfig = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "home-manager.backup";
    home-manager.extraSpecialArgs = extraSpecialArgs;
    home-manager.users.${vars.username}.imports = homeModules ++ hostHomeModules;
  };

  builder = forPlatform {
    darwin = inputs.nix-darwin.lib.darwinSystem;
    nixos = inputs.nixpkgs.lib.nixosSystem;
  };

  platformConfiguration = forPlatform {
    darwin = "darwinConfigurations";
    nixos = "nixosConfigurations";
  };

  modules = [
    nixpkgsModule
  ]
  ++ systemModules
  ++ hostSystemModules
  ++ [
    homeManagerModule
    homeManagerConfig
  ];
in
{
  ${platformConfiguration}.${hostname} = builder { inherit system specialArgs modules; };
}
