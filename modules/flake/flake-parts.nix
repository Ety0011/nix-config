{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.treefmt-nix.flakeModule
  ];

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
}
