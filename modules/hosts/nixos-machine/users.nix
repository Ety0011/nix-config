{ inputs, ... }:
{
  flake.modules.nixos.nixos-machine = {
    imports = with inputs.self.modules.nixos; [
      ety
    ];
  };
}
