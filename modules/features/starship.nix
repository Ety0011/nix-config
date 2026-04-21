{ ... }:
{
  flake.modules.homeManager.starship = {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableTransience = true; # collapse old prompts for a clean terminal
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
