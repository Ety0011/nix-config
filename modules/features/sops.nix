{ inputs, ... }:
{
  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    # sops.defaultSopsFile set per-host via collector pattern
  };

  flake.modules.darwin.sops = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
  };

  flake.modules.homeManager.sops = {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
  };
}
