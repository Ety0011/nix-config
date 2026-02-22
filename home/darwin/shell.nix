{ ... }:

{
  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      update = "sudo darwin-rebuild switch --flake ~/nix-config";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # Automatically adds hook to zsh
    nix-direnv.enable = true; # Enable nix-direnv for caching
  };

  # Starship prompt (optional but recommended)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
}
