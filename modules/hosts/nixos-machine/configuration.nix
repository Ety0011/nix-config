{ inputs, ... }:
{
  flake.modules.nixos.nixos-machine = {
    imports = with inputs.self.modules.nixos; [
      host-base  # nix settings, GC, home-manager, disko, sops, ssh server
    ];

    networking.hostName = "nixos-machine";
  };
}
