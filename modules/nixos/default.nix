{ lib, ... }:
{
  imports = (lib.custom.scanModules ./.) ++ [
    (lib.custom.relativeToRoot "modules/core")
  ];
}
