{ ... }:
{
  # Declarative disk layout via disko.
  # disko is imported via host-base → disko-wiring.
  # Define your partition scheme here, for example:
  #
  #   flake.modules.nixos.nixos-machine = {
  #     disko.devices.disk.main = {
  #       device = "/dev/sda";
  #       type = "disk";
  #       content = {
  #         type = "gpt";
  #         partitions = { ... };
  #       };
  #     };
  #   };
  #
  # See: https://github.com/nix-community/disko/blob/master/docs/reference.md

  flake.modules.nixos.nixos-machine = { };
}
