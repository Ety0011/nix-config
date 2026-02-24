{ ... }:
{
  flake.modules.nixos.zsh = {
    programs.zsh.enable = true;
  };

  flake.modules.darwin.zsh = {
    programs.zsh.enable = true;
  };

  flake.modules.homeManager.zsh =
    { pkgs, ... }:
    {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        history = {
          size = 10000;
          ignoreDups = true;
          ignoreSpace = true;
          share = true;
        };
        shellAliases = {
          update =
            if pkgs.stdenv.isDarwin then
              "sudo darwin-rebuild switch --flake ~/nix-config"
            else
              "sudo nixos-rebuild switch --flake ~/nix-config";
        };
      };
    };
}
