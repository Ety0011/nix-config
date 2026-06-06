{ lib, config, ... }:
let
  profiles = config.users.profiles;
in
{
  flake.modules.homeManager = lib.genAttrs (lib.attrNames profiles) (
    username:
    lib.mkIf (profiles.${username}.features.git.enable) {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };
      programs.git = {
        enable = true;
        ignores = [
          ".direnv/"
          ".envrc"
          ".venv/"
          ".DS_Store"
          "*.swp"
        ];
        settings = {
          init.defaultBranch = "main";
          pull.rebase = false;
          push.autoSetupRemote = true;
        };
      };
    }
  );
}
