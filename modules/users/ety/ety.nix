{ self, lib, ... }:
let
  username = "ety";
in
{
  flake.modules = lib.mkMerge [
    (self.lib.mkUser username true)

    {
      nixos.${username} = { };

      darwin.${username} = {
        homebrew = {
          enable = true;
          onActivation.cleanup = "zap";
          casks = [
            "obs"
            "unity-hub"
            "microsoft-teams"
          ];
        };
      };

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
            nixTools
          ];

          programs.git.settings.user = {
            name = "Etienne";
            email = "etienne.orio@orio.ch";
          };

          home.packages = with pkgs; [
            lldb
            rectangle
          ];
        };
    }
  ];
}
