# Install from helios (see docs/research/best-of-nix.md §4.1):
#   1. Set the disk in _disko.nix (`lsblk` on typhon's installer).
#   2. nix run github:nix-community/nixos-anywhere -- --flake .#typhon \
#        --disk-encryption-keys /tmp/secret.key <(read -s p; printf %s "$p") \
#        --generate-hardware-config nixos-facter ./modules/hosts/typhon/facter.json \
#        --phases kexec,disko,install root@<installer-ip>
#   3. Set ety's password before the first boot:
#        ssh root@<installer-ip> nixos-enter --root /mnt -c 'passwd ety'
#      then reboot, and replace _hardware.nix with the facter report.
{ config, inputs, ... }:
{
  configurations.nixos.typhon.module = {
    imports =
      (with config.flake.modules.nixos; [
        base
        desktop
        ety
      ])
      ++ [
        inputs.disko.nixosModules.disko
        ./_disko.nix
        ./_hardware.nix
      ];
    system.stateVersion = "26.05";
    home-manager.users.ety.home.stateVersion = "26.05";
  };
}
