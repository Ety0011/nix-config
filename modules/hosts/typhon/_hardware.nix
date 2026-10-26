# Placeholder until typhon is installed. Replace with
# `hardware.facter.reportPath = ./facter.json;` once nixos-anywhere has
# generated the report (`--generate-hardware-config nixos-facter ./facter.json`).
{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;
}
