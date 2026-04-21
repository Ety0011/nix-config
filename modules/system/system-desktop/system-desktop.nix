{ inputs, ... }:
{
  # Layer 3 — CLI system extended for interactive desktop use.

  flake.modules.darwin.system-desktop = {
    imports = with inputs.self.modules.darwin; [
      system-cli
      window-manager
      system-defaults
    ];
  };

  # NixOS desktop would add gnome/kde here when needed.
  # flake.modules.nixos.system-desktop = { ... };

  flake.modules.homeManager.system-desktop = {
    imports = with inputs.self.modules.homeManager; [
      system-cli
    ];
  };
}
