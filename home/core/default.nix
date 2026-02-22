{ lib, ... }:
{
  imports = lib.custom.scanModules ./.;
}
