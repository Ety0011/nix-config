{
  flake.modules.nixos.base.programs.zsh.enable = true;

  flake.modules.homeManager.base.programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 100000;
      save = 100000;
      extended = true;
    };

  };
}
