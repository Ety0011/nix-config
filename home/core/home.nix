# modules/base/home/home.nix
{ vars, ... }:
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
