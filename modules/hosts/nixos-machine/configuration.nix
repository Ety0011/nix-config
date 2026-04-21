{ inputs, ... }:
{
  # Defines the nixos-machine nixos module.
  # Users are wired in users/ety.nix; hardware in hardware.nix; disks in filesystem.nix.
  flake.modules.nixos.nixos-machine = {
    imports = with inputs.self.modules.nixos; [
      system-cli # layer 2: system-minimal → system-cli (includes disko, sops, ssh, home-manager)
    ];

    networking.hostName = "nixos-machine";
  };
}
