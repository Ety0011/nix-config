{ inputs, ... }:
{
  # Wire the ety user into this host.
  # The actual user definition lives in modules/users/ety/ety.nix.
  flake.modules.darwin.mac-machine = {
    imports = with inputs.self.modules.darwin; [
      ety
    ];
  };
}
