{ lib, ... }:
{
  imports = (lib.custom.scanModules ./.) ++ [
    (lib.custom.relativeToRoot "home/core")
  ];
}
