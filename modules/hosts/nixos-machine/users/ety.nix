{ inputs, ... }:
{
  # Wire the ety user into this host.
  # The actual user definition lives in modules/users/ety/ety.nix.
  flake.modules.nixos.nixos-machine = {
    imports = with inputs.self.modules.nixos; [
      ety
    ];
  };
}
