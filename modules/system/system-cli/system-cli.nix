{ inputs, ... }:
{
  # Layer 2 — minimal system extended with home-manager, secrets, SSH, and CLI tooling.
  # All machines (headless and desktop) use this as their base.

  flake.modules.nixos.system-cli = {
    imports = with inputs.self.modules.nixos; [
      system-minimal
      home-manager-wiring
      disko-wiring
      sops
      ssh
    ];
  };

  flake.modules.darwin.system-cli = {
    imports = with inputs.self.modules.darwin; [
      system-minimal
      home-manager-wiring
      sops
      # ssh openssh server not available on darwin via nix-darwin the same way;
      # SSH client config is handled in homeManager.ssh
    ];
  };

  flake.modules.homeManager.system-cli = {
    imports = with inputs.self.modules.homeManager; [
      system-minimal
      sops
      ssh
      zsh
      git
      direnv
      starship
      nix-tools
    ];
  };
}
