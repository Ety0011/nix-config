# GPT: 1 GiB ESP + LUKS2 container holding btrfs subvolumes (see docs/adr/0002).
# `device` is a placeholder until the real disk is known (`lsblk` on typhon).
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            # nixos-anywhere copies the passphrase here for the install only.
            passwordFile = "/tmp/secret.key";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes =
                let
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                in
                {
                  "/root" = {
                    mountpoint = "/";
                    inherit mountOptions;
                  };
                  "/home" = {
                    mountpoint = "/home";
                    inherit mountOptions;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    inherit mountOptions;
                  };
                };
            };
          };
        };
      };
    };
  };
}
