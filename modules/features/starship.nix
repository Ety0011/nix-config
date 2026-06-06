{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf
      (profiles.${username}.features.starship.enable && profiles.${username}.features.starship.allowed)
      {
        programs.starship = {
          enable = true;
          enableZshIntegration = true;
          enableTransience = true;
          settings = {
            add_newline = true;
            character = {
              success_symbol = "[➜](bold green)";
              error_symbol = "[➜](bold red)";
            };
          };
        };
      }
  );
}
