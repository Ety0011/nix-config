# typhon disk layout: LUKS2 + btrfs subvolumes via disko

typhon is a desktop, so its disk is a GPT with a 1 GiB ESP and one LUKS2 container holding btrfs subvolumes for `/`, `/home`, `/nix` and `/var/log` (zstd compression, `noatime`), declared with disko and installed with nixos-anywhere. Encryption protects data at rest on a machine that may leave the house or be sold; btrfs subvolumes allow snapshots later (e.g. snapper on `/home`) without repartitioning. Swap is zram, not a partition.

## Considered Options

- **Plain ext4:** simplest, but no snapshots or compression, and changing later means reinstalling.
- **ZFS:** strong snapshots, but an out-of-tree kernel module that can lag new kernels.
- **Impermanence (root wiped on boot):** deferred; the `/root` subvolume can be rolled back later without changing the partition layout.

## Consequences

- The disk is unlocked by a passphrase typed at boot; nixos-anywhere needs it as `/tmp/secret.key` during install.
- `device` in `modules/hosts/typhon/_disko.nix` is a placeholder; set it from `lsblk` before installing.
