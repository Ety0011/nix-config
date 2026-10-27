{
  flake.modules.nixos.base.programs.zsh.enable = true;

  flake.modules.homeManager.base.programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

  };
}
