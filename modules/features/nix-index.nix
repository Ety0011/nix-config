# Prebuilt nix-index database: `nix-locate`, command-not-found, and comma
# (`, cowsay` runs a program without installing it).
{ inputs, ... }:
{
  flake.modules.homeManager.base = {
    imports = [ inputs.nix-index-database.homeModules.default ];
    programs.nix-index-database.comma.enable = true;
  };
}
