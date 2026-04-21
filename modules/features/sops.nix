{ inputs, ... }:
{
  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    # sops.defaultSopsFile is set per-host via the host module
  };

  flake.modules.darwin.sops = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
  };

  flake.modules.homeManager.sops = {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
  };
}
