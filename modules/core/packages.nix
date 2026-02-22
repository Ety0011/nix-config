{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    git
    nixfmt-rfc-style
    syncthing
  ];
}
