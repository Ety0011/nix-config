{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rectangle
  ];
}
