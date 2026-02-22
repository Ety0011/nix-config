# modules/darwin/system/apps.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rectangle
  ];
}
