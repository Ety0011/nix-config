{ lib, hostname }:
let
  vars = import (lib.custom.relativeToRoot "hosts/${hostname}/vars.nix");
  systemModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/system.nix") ];
  homeModules = [ (lib.custom.relativeToRoot "hosts/${hostname}/home.nix") ];
  os = if lib.hasSuffix "darwin" vars.system then "darwin" else "nixos";
in
{
  inherit
    vars
    os
    systemModules
    homeModules
    ;
}
