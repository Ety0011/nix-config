{ inputs, ... }:
{
  # System-level additions for hosts with a graphical desktop.
  # Covers OS appearance and window management — not user applications or shells.

  flake.modules.darwin.host-desktop = {
    imports = with inputs.self.modules.darwin; [
      host-base
      system-defaults
      window-manager
    ];
  };

  # Placeholder: a NixOS desktop host would import host-base + gnome/kde here.
  # flake.modules.nixos.host-desktop = {
  #   imports = with inputs.self.modules.nixos; [
  #     host-base
  #     # gnome or kde feature module
  #   ];
  # };
}
