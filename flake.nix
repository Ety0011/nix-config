{
  description = "Ety nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      mac-app-util,
      ...
    }:
    let
      username = "ety";
      hostname = "Etiennes-MacBook-Pro";
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit
            inputs
            username
            hostname
            self
            ;
        };
        modules = [
          ./modules/darwin
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          (
            {
              pkgs,
              config,
              inputs,
              ...
            }:
            {
              home-manager.sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs username; };
              home-manager.users.${username} = import ./modules/home-manager;
            }
          )
        ];
      };
    };
}
