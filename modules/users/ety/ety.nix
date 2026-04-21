{ self, lib, ... }:
let
  username = "ety";
in
{
  # Use the factory to generate the standard account boilerplate for all three
  # contexts (nixos / darwin / homeManager), then merge in ety-specific extras.
  flake.modules = lib.mkMerge [
    (self.factory.user username true)

    {
      # ── NixOS extras ────────────────────────────────────────────────────────
      # The factory already creates users.users.ety and wires home-manager.
      # Add any NixOS-specific extras here.
      nixos.${username} = { };

      # ── Darwin extras ────────────────────────────────────────────────────────
      darwin.${username} = { };

      # ── homeManager config ───────────────────────────────────────────────────
      homeManager.${username} =
        { pkgs, ... }:
        {
          imports = with self.modules.homeManager; [
            system-desktop # transitively pulls in: system-cli → system-minimal
                           # which includes: zsh, git, direnv, starship, nix-tools,
                           #                 ssh, sops, vscode, system defaults
          ];

          # Git identity belongs in the user module, not the generic git feature.
          programs.git.settings.user = {
            name = "Etienne";
            email = "etienne.orio@orio.ch";
          };

          home.packages = with pkgs; [
            lldb
          ];
        };
    }
  ];
}
