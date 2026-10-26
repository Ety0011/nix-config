# Hands every Host the perSystem pkgs (with the `unstable` overlay) and pins
# the flake registry, so nixpkgs is imported once per system.
{ inputs, withSystem, ... }:
let
  module =
    { config, ... }:
    {
      nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
      system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    };
in
{
  flake.modules.darwin.base = {
    imports = [ module ];
    nix.registry.nixpkgs.flake = inputs.nixpkgs-darwin;
  };

  flake.modules.nixos.base = {
    imports = [ module ];
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
  };
}
