{
  # Home Manager runs compinit in ~/.zshrc; the global one in /etc/zshrc would
  # make every shell run it twice. /etc/zshenv still puts the system profiles'
  # completions on fpath.
  flake.modules.nixos.base.programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };
  flake.modules.darwin.base.programs.zsh.enableGlobalCompInit = false;

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
