{
  flake.modules.darwin.base.programs.zsh.enable = true;
  flake.modules.nixos.base.programs.zsh.enable = true;

  flake.modules.homeManager.base.programs.zsh = {
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
  };
}
