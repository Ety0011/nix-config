{ ... }:
{
  # Platform and hardware settings for nixos-machine.
  flake.modules.nixos.nixos-machine = {
    nixpkgs.hostPlatform = "x86_64-linux";

    # TODO: import the generated hardware-configuration.nix after first install:
    #   hardware-configuration = /etc/nixos/hardware-configuration.nix
    # Or manage it with disko (see filesystem.nix).
  };
}
