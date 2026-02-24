{ ... }:
{
  flake.modules.homeManager.starship = {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableTransience = true; # collapses old prompts — clean terminal
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
  };
}
