{ inputs, ... }:
let
  hostName = "nixos-machine";
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos system hostName;

  # Hardware-specific overrides — add kernel modules, CPU microcode, or
  # hardware-configuration.nix import here.
  flake.modules.nixos.${hostName} = { };
}
