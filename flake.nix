{
  description = "Ety NixOS and macOS configurations";
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
  };
  outputs =
    inputs:
    let
      lib = import ./lib {
        inherit (inputs.nixpkgs) lib;
        root = ./.;
      };
      vars = import ./vars { inherit lib; };
    in
    lib.mergeAttrsList (
      map (
        hostname:
        lib.custom.makeConfiguration {
          inherit
            inputs
            lib
            vars
            hostname
            ;
        }
      ) (lib.custom.scanDirs ./hosts)
    );
}
