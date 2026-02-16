{ pkgs, ... }:

{
  imports = [
    ./nix.nix # general Nix configuration
    ./system.nix # general system settings
    ./common.nix # user-specific shared logic
  ];
}
