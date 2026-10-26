# Placeholder until typhon is installed; replace with the output of
# `nixos-generate-config`.
{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
