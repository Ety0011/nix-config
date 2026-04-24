{ self, lib, ... }:
let
  username = "ety";
in
{
  flake.modules = lib.mkMerge [
    (self.factory.user username true)

    {
      # NixOS account extras (factory already creates the account and wires home-manager)
      nixos.${username} = { };

      # Darwin account extras
      darwin.${username} = { };

      # homeManager: ety chooses exactly the features they want.
      # This is personal preference — nothing here belongs in host config.
      homeManager.${username} =
        { pkgs, ... }:
        {
          imports = with self.modules.homeManager; [
            sops
            ssh
            zsh
            git
            direnv
            starship
            nix-tools
            vscode
          ];

          # Git identity belongs to the user, not to the generic git feature.
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
