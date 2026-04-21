{ ... }:
{
  flake.modules.darwin."Etiennes-MacBook-Pro" = {
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
